use practice;

/**** RFM 분석용 데이터 마트 생성 ****/
create table RFM as
select a.*,
	b.구매금액,
    b.구매빈도
from customer as a 
left join
( 
select a.mem_no,
	a.sales_qty * b.price as 구매금액, /* Monetary */
    count(a.order_no) as 구매빈도 /* Frequency */
from sales as a
left join product as b
on a.product_code = b.product_code
where year(order_date) = '2020' /* Recency */
group by a.mem_no
) as b
on a.mem_no = b.mem_no;

/* 확인 */
select *
from rfm;

/* 1. rfm 세분화별 회원수 */
select 회원세분화,
	count(mem_no) as 회원수
from (
select *,
	case when 구매금액 > 5000000 then 'VIP'
		when 구매금액 > 1000000 or 구매빈도 > 3 then '우수회원'
        when 구매금액 > 0 then '일반회원'
        else '잠재회원' end as 회원세분화
from rfm
) as a
group by 회원세분화
order by 회원수 asc;

/* 2. RFM 세분화별 매출액 */
select 회원세분화,
	sum(구매금액) as 구매금액
from (
select *,
	case when 구매금액 > 5000000 then 'VIP'
		when 구매금액 > 1000000 or 구매빈도 > 3 then '우수회원'
        when 구매금액 > 0 then '일반회원'
        else '잠재회원' end as 회원세분화
from rfm
) as a
group by 회원세분화
order by 구매금액 desc;


/* 3. RFM 세분화별 인당 구매금액 */
select 회원세분화,
	sum(구매금액) / count(mem_no) as 인당_구매금액
from (
select *,
	case when 구매금액 > 5000000 then 'VIP'
		when 구매금액 > 1000000 or 구매빈도 > 3 then '우수회원'
        when 구매금액 > 0 then '일반회원'
        else '잠재회원' end as 회원세분화
from rfm
) as a
group by 회원세분화
order by 구매금액 desc;





