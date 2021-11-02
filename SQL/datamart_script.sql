use practice;

/** 데이터 마트 **/
/* 회원 구매 정보 임시테이블로 만들기*/
create temporary table customer_pur_info as
select a.mem_no,
	a.gender,
    a.birthday,
    a.addr,
    a.join_date,
    sum(b.sales_qty * c.price) as 구매금액,
    count(b.order_no) as 구매횟수,
    sum(b.sales_qty) as 구매수량
from customer as a
left join sales as b
on a.mem_no = b.mem_no
left join product as c
on b.product_code = c.product_code
group by a.mem_no, a.gender, a.birthday, a.addr, a.join_date;

select *
from customer_pur_info;


/* 회원 연령대 */
/* 생년월일 -> 나이 */
select *,
	2021-year(birthday) + 1 as 나이
from customer;

/* 생년월일 -> 나이 -> 연령대 */
select *,
	case when 나이 < 10 then '10대 미만'
		when 나이 < 20 then '10대'
		when 나이 < 30 then '20대'
		when 나이 < 40 then '30대'
		when 나이 < 50 then '40대'
		else '50대 이상' end as 연령대
from (select *,
		2021-year(birthday) + 1 as 나이
		from customer) as a;

/* 회원 연령대 임시테이블 */
create temporary table customer_ageband as
select a.*,
	case when 나이 < 10 then '10대 미만'
		when 나이 < 20 then '10대'
		when 나이 < 30 then '20대'
		when 나이 < 40 then '30대'
		when 나이 < 50 then '40대'
		else '50대 이상' end as 연령대
from (select *,
		2021-year(birthday) + 1 as 나이
		from customer) as a;
        
select *
from customer_ageband;

/* 회원 구매정보 + 연령대 임시테이블 */
create temporary table customer_pur_info_ageband as
select a.*,
	b.연령대
from customer_pur_info as a
left join customer_ageband as b
on a.mem_no = b.mem_no;

select *
from customer_pur_info_ageband;


/***** 회원 선호 카테고리 *****/

/* 회원 및 카테고리별 구매횟수 순위 */
select a.mem_no,
		b.category,
        count(a.order_no) as 구매횟수,
        row_number() over(partition by a.mem_no order by count(a.order_no) desc) as 구매횟수_순위
from sales as a
left join product as b
on a.product_code = b.product_code
group by a.mem_no, b.category;


/* 회원 및 카테고리별 구매횟수 순위 + 구매횟수 순위 1위만 필터링 */
select *
from (
	select a.mem_no,
			b.category,
			count(a.order_no) as 구매횟수,
			row_number() over(partition by a.mem_no order by count(a.order_no) desc) as 구매횟수_순위
	from sales as a
	left join product as b
	on a.product_code = b.product_code
	group by a.mem_no, b.category
) as a
where 구매횟수_순위 = 1;


/* 회원 선호 카테고리 임시테이블 */
create temporary table customer_pre_category as
select *
from (
	select a.mem_no,
			b.category,
			count(a.order_no) as 구매횟수,
			row_number() over(partition by a.mem_no order by count(a.order_no) desc) as 구매횟수_순위
	from sales as a
	left join product as b
	on a.product_code = b.product_code
	group by a.mem_no, b.category
) as a
where 구매횟수_순위 = 1;

/* 확인 */
select *
from customer_pre_category;


/* 회원 구매정보 + 연령대 + 선호 카테고리 임시테이블 */
create temporary table customer_pur_info_ageband_pre_category as
select a.*,
	b.category as pre_category
from customer_pur_info_ageband as a
left join customer_pre_category as b
on a.mem_no = b.mem_no;


select *
from customer_pur_info_ageband_pre_category;


/* 회원 분석용 데이터 마트 생성 (회원 구매정보 + 연령대 + 선호 카테고리 임시테이블) */

create table customer_mart as
select *
from customer_pur_info_ageband_pre_category;

select *
from customer_mart;


/** 데이터 정합성 확인 **/
/* 데이터 마트 회원수의 중복은 없는가? */
select count(mem_no),
	count(distinct mem_no)
from customer_mart; 

/* 요약 및 파생변수 오류 확인 */

select sum(a.sales_qty * b.price) as 구매금액
	,count(a.order_no) as 구매횟수
    ,sum(a.sales_qty) as 구매수량
from sales as a
left join product as b
on a.product_code = b.product_code
where mem_no = '1000005';

select *
from sales as a
left join product as b
on a.product_code = b.product_code
where mem_no = '1000005';

/** 데이터 마트의 구매자 비중(%)의 오류는 없는가? **/

/* customer 테이블 기준, sales 테이블 구매 회원번호 left join 결합 */
select *
from customer as a
left join (
	select distinct mem_no
    from sales
) as b
on a.mem_no = b.mem_no;

/* 구매여부 추가 */
select *,
	case when b.mem_no is not null then '구매'
		else '미구매' end as 구매여부
from customer as a
left join (
	select distinct mem_no
    from sales
) as b
on a.mem_no = b.mem_no;


/* 구매여부별, 회원수 */

select 구매여부,
	count(mem_no) as 회원수
from(
	select a.*,
		case when b.mem_no is not null then '구매'
			else '미구매' end as 구매여부
	from customer as a
	left join (
		select distinct mem_no
		from sales
	) as b
	on a.mem_no = b.mem_no
    ) as a
group by 구매여부;




