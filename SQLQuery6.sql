select COUNT(movieId) as numbers,genres
from movies_genres
group by genres
/*1\ͳ��ÿ����ǩ�µ�Ӱ������*/

select AVG(rating)as scores,genres
from movies_genres,ratings
where movies_genres.movieId=ratings.movieId
group by genres
/*2\ͳ��ÿ���Ӱ��ƽ������*/



/*
	SELECT tag_numbers+rating_numbers as user_numbers,R.rating_id as mo_id
	from
		(
		select count(movieId)as tag_numbers,movieId as tag_id
		from tags 
		group by movieId)
		T
		full outer join
		(select count(movieId)as rating_numbers,movieId as rating_id
		from ratings
		group by movieId)
		R
		ON T.tag_id=R.rating_id
	WHERE tag_numbers IS NOT NULL
	AND   rating_numbers IS NOT NULL
	/*�ϱ�Ϊ��Ӱ����ͳ��,�Ͽ��ѯ���ܹ����ں�����ѯ����Ϊ�м��*/
*/


select mo_id, user_numbers
from   (SELECT tag_numbers+rating_numbers as user_numbers,R.rating_id as mo_id
	   from
		(
		select count(movieId)as tag_numbers,movieId as tag_id
		from tags 
		group by movieId)
		T
		full outer join
		(select count(movieId)as rating_numbers,movieId as rating_id
		from ratings
		group by movieId)
		R
		ON T.tag_id=R.rating_id
	  WHERE tag_numbers IS NOT NULL
	  AND   rating_numbers IS NOT NULL)as watching
where user_numbers>200
order by mo_id
/*�ϱ���Ϊ�м������Ӱ��������200�ĵ�Ӱ*/


select top 10 movieId,AVG(rating)as scores,user_numbers
from ratings,(select mo_id, user_numbers
			  from   (SELECT tag_numbers+rating_numbers as user_numbers,R.rating_id as mo_id
					  from
					(
					select count(movieId)as tag_numbers,movieId as tag_id
					from tags 
					group by movieId)T
			full outer join
			(select count(movieId)as rating_numbers,movieId as rating_id
			from ratings
			group by movieId)
			R
			ON T.tag_id=R.rating_id
			WHERE tag_numbers IS NOT NULL
			AND   rating_numbers IS NOT NULL)as watching
            where user_numbers>200)

			as bigerthan200
where bigerthan200.mo_id=ratings.movieId
group by movieId,user_numbers
order by AVG(rating) desc

/*3\���ϲ�ѯΪ��Ӱ��������200��ƽ������ǰʮ�ĵ�Ӱ��������ͣ�ֻ��Ҫ������ʽΪ����*/






select  movies_genres.genres, ratings.movieId,AVG(rating) as scores
from ratings,movies_genres 		 
where ratings.movieId in
	(select top 10 ratings.movieId
	from ratings,movies_genres

    where ratings.movieId=movies_genres.movieId
	and ratings.movieId in(select mo_id
						from   (SELECT tag_numbers+rating_numbers as user_numbers,R.rating_id as mo_id
								from
								(
								select count(movieId)as tag_numbers,movieId as tag_id
								from tags 
								group by movieId)
								T
								full outer join
								(select count(movieId)as rating_numbers,movieId as rating_id
								from ratings
								group by movieId)
								R
								ON T.tag_id=R.rating_id
								WHERE tag_numbers IS NOT NULL
								AND   rating_numbers IS NOT NULL)as watching
						where user_numbers>200)

    group by movies_genres.genres, ratings.movieId

    order by AVG(rating)desc)
group by movies_genres.genres, ratings.movieId
order by movies_genres.genres
/*4����Ϊ��ѯÿ�����͵�Ӱ��������ֵ��ƽ��������ǰʮ�ĵ�Ӱ�����������ʮ����*/



/*
SELECT distinct ta,rat,R.rating_id as mo_id
from
	(select movieId as tag_id,tag as ta
	from tags )T
	full outer join
    (select movieId as rating_id,rating as rat
	from ratings)R
	ON T.tag_id=R.rating_id
where rat is not null

/*һ������Ӱid���ǩ���������������ı�tag����Ϊ�գ�*/						
*/


select SUM(A.rat)/count(A.mo_id)as tagIsNull_avg
from ( SELECT distinct ta,rat,R.rating_id as mo_id
	 from
		(select movieId as tag_id,tag as ta
		from tags )T
		full outer join
		(select movieId as rating_id,rating as rat
		from ratings)R
		ON T.tag_id=R.rating_id
	where rat is not null
	AND ta IS NULL)as A

select SUM(B.rat)/count(B.mo_id) as tagIsNotNull_avg
from ( SELECT distinct ta,rat,R.rating_id as mo_id
	 from
		(select movieId as tag_id,tag as ta
		from tags )T
		full outer join
		(select movieId as rating_id,rating as rat
		from ratings)R
		ON T.tag_id=R.rating_id
	where rat is not null
	AND ta IS not NULL)as B





