SET STATISTICS TIME ON --ִ��ʱ��
SET STATISTICS IO ON --IO��ȡ
use Datamining

if exists(select * from sysobjects where xtype='tf' and name='ttttt')
	drop function ttttt
go

CREATE FUNCTION ttttt(@s nvarchar(max))
returns @t table (id int)
as
begin
	insert into @t 
	select top 10 ratings.movieId
	from ratings,movies_genres

    where ratings.movieId=movies_genres.movieId and genres=@s
	and ratings.movieId in
	(
		select mo_id from
		(SELECT isnull(tag_numbers+rating_numbers, rating_numbers) as user_numbers,R.rating_id as mo_id
								from
								(
								select count(movieId)as tag_numbers,movieId as tag_id
								from tags 
								group by movieId) as T
								full outer join
								(select count(movieId)as rating_numbers,movieId as rating_id
								from ratings
								group by movieId) as R
								ON T.tag_id=R.rating_id
								)as watching
						where user_numbers>200)

    group by movies_genres.genres, ratings.movieId
	return
end
go


select FF.genres, F.id from (select distinct genres from movies_genres) as FF cross apply ttttt(FF.genres) as F
order by genres

-- �����ǵ��ĸ���ѯ

;
with T1 AS
(select dbo.ratings.userId, AVG(rating) as scores_withTag from dbo.ratings where exists(
select userId, movieId from tags where userId=ratings.userId and movieId=ratings.movieId)
group by userId
), 
	T2 AS
(
select userId, AVG(rating) as scores_withoutTag from ratings where not exists(
select userId, movieId from tags where userId=ratings.userId and movieId=ratings.movieId)
group by userId
)
select T1.userId, scores_withTag, scores_withoutTag
from T1, T2
where T1.userId=T2.userId
order by userId

-- ����ǵ������ѯ