use DataMining;


if exists(select * from syscolumns where id=object_id('tags') and name='times')
	alter table tags drop column times
if exists(select * from syscolumns where id=object_id('ratings') and name='times')
	alter table ratings drop column times

alter table tags add times datetime
alter table ratings add times datetime
go

update tags set times = dateadd(second, timestamp, '1970-01-01 00:00:00')
update ratings set times = dateadd(second, timestamp, '1970-01-01 00:00:00')

-- timestamp to date


if exists( select * from sysobjects where id=object_id('movies_year') )
	drop table movies_year

create table movies_year(movieId int primary key, title nvarchar(MAX), pub_date int)

if exists(select * from sysobjects where xtype='fn' and name='Fun_GetNumPart')
	drop function Fun_GetNumPart
go
CREATE FUNCTION Fun_GetNumPart  
( @Str NVARCHAR(MAX) ) 
RETURNS NVARCHAR(MAX)   
AS   
BEGIN   
    if PATINDEX('%(19[0-9][0-9])%',@Str)>0   
    BEGIN   
        SET @Str=substring(@str, patindex('%(19[0-9][0-9])%', @str)+1, 4) --删掉非数字的字符
    END   
	else if patindex('%(20[0-9][0-9])%', @Str) > 0
	BEGIN
		set @Str=substring(@str, patindex('%(20[0-9][0-9])%', @str)+1, 4)
	END
	else
	BEGIN
		set @Str=NULL
	END
    RETURN @Str 
END   
go

insert into movies_year 
	select movieId, 
	reverse(stuff(reverse(title), 1, charindex('(', reverse(title)), '')), 
	dbo.Fun_GetNumPart(title)
	from movies

-- title -> title, year 


if exists( select * from sysobjects where id=object_id('movies_genres'))
	drop table movies_genres

create table movies_genres(movieId int, genres nvarchar(100))

if exists(select * from sysobjects where xtype='tf' and name='Fun_splitString')
	drop function Fun_splitString
go

CREATE FUNCTION Fun_splitString(@s nvarchar(max))
returns @t table (string nvarchar(100))
as
begin
	declare @restStr nvarchar(MAX)
	declare @firstStr nvarchar(100)
	set @restStr = @s+'|'
	while (len(@restStr)>0)
	begin
		set @firstStr = left(@restStr, CHARINDEX('|', @restStr)-1)
		insert @t values(@firstStr)
		set @restStr = stuff(@restStr, 1, CHARINDEX('|', @restStr), '')
	end
	return
end
go

insert into movies_genres
	select movies.movieId, F.string from movies cross apply Fun_splitString(movies.genres) as F

--movieId genres 


if exists( select * from sysobjects where id=object_id('movies_index') )
	drop table movies_index
select movies.movieId, identity(int, 1, 1) as ind into movies_index from movies
alter table movies_index add constraint movies_ind_key primary key(movieId)

if exists( select * from sysobjects where id=object_id('users_index') )
	drop table users_index
select distinct userId, identity(int, 1, 1) as ind into users_index from ratings
alter table users_index add constraint users_ind_key primary key(userId) 


if exists( select * from sysobjects where id=object_id('users_movies') )
	drop table users_movies
create table users_movies(users_ind int, movies_ind int, rating float primary key(users_ind, movies_ind))


insert into users_movies
	select users_index.ind, movies_index.ind, ratings.rating from ratings, users_index, movies_index 
		where ratings.userId=users_index.userId and ratings.movieId=movies_index.movieId

create index user_index on users_movies(users_ind)
create index movie_index on users_movies(movies_ind) 

-- user_movie matrix


if exists( select * from sysobjects where id=object_id('users_relation') )
	drop table users_relation
create table users_relation(userId1 int, userId2 int, similarity float primary key(userId1, userId2))

insert into users_relation
select r4.id1, r4.id2, s/(r3.sq*r5.sq) from
(select r1.userId id1, r2.userId id2, sum(r1.rating*r2.rating) s from ratings r1, ratings r2
where r1.userId < r2.userId and r1.movieId = r2.movieId
group by r1.userId, r2.userId) r4, (select userId, sum(rating*rating) sq from ratings group by userId) r3, (select userId, sum(rating*rating) sq from ratings group by userId) r5
where r3.userId=r4.id1 and r5.userId=r4.id2

-- user_relation matrix
