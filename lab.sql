use master
create database lab9;
go
use lab9;

--drop table users;
--drop table users

create table users
(
    Id         bigint primary key,
    name varchar(255) not null,
    nickname   varchar(128) not null unique,
    age        int,
    deleted    bit          not null default 0
)

--drop table balance;
go
create table balance
(
    Id bigint primary key identity (1, 1),
    user_id bigint not null foreign key references users(Id) on update cascade on delete cascade,
    amount int,
)

--drop trigger trigger_insert;
-- Создаем триггер на вставку

create trigger trigger_insert
    on users
    instead of insert
    as
begin
    if exists(select * from inserted where age <= 0)
        begin
            throw 50001, 'Age cannot be less or equal to 0', 1;
            return;
        end

    insert into users(Id, name, nickname, age, deleted)
    select Id, name, nickname, age, deleted
    from inserted;
    print 'Data Inserted!';
end

go


--drop trigger trigger_delete;
-- Создаем триггер на удаление
create trigger trigger_delete
    on users
    instead of delete
    AS
begin
    update users set deleted = 1 where Id in (select Id from deleted)
end
go

--drop trigger trigger_update;
-- Создаем триггер на обновление
create trigger trigger_update
    on users
    after update
    as
begin
    if update(Id)
        begin
            throw 50001, 'Id changing not allowed!', 1;
            return;
        end
    if exists(select * from inserted where age <= 0)
        begin
            throw 50001, 'Age cannot be less or equal to 0', 1;
            return
        end
end
go

--drop trigger trigger_after_update;
create trigger trigger_after_update
    on balance
    after update
    as
begin
    if update(user_id)
        begin
            throw 50001, 'id changing not allowed', 1;
            return;
        end
end
go

-- Успешно добавляем данные в таблицу
insert into users (Id, name, nickname, age) values (10, 'Sergey', 'pearjam', 30);
insert into balance (user_id, amount) values(10, 10000);
-- Удаляем данные из таблицы
delete from users where nickname = 'pearjam';
-- Пытаемся изменить данные на некорректные
update users set age = 0 where nickname = 'pearjam';
update balance set user_id = 3 where user_id = 4;


--drop view view_users;
create view view_users as
    select u.Id, u.name, u.nickname, u.age, w.amount
    from users u
    inner join balance w on u.Id = w.user_id
    where deleted = 0;

--drop trigger trigger_instead_view;
-- Создаем триггер на вставку
create trigger trigger_instead_view
    on view_users
    instead of insert
    as
begin
    insert into users(Id, name, nickname, age)
    select Id, name, nickname, age
    from inserted;

    insert into balance(user_id, amount)
    select Id, amount
    from inserted;
end
go

--drop trigger trigger_delete_view;
-- Создаем триггер на удаление
create trigger trigger_delete_view
    on view_users
    instead of delete
    AS
begin
    delete from users where Id in (select Id from deleted)
end
go

--drop trigger trigger_view_after_update;
-- Создаем триггер на обновление
create trigger trigger_view_after_update
    on view_users
    instead of update
    as
begin
    update users
    set name = i.name, nickname = i.nickname, age = i.age
    from users u
    inner join inserted i on u.Id = i.Id;

    update balance
    set amount = i.amount
    from balance w
    inner join inserted i on w.user_id = i.Id;
end
go

-- Возвращаем из удаленных
update users set deleted = 0 where nickname = 'pearjam';

select * from view_users;
update view_users set id = id+5
select * from view_users
delete from view_users where nickname = 'pearjam';

insert into view_users (Id, name, nickname, age, amount) values (15, 'Alex', 'alex66', 50, 800);
update view_users set name = 'Alex', age = 30 where nickname = 'alex66';

select * from view_users
