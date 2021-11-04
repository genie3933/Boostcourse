use practice;

/*********************SQL 데이터 분석 단원 정리*************************/
select *
from customer;

/***************SQL 데이터 분석 단원 분석용 데이터 마트***************/
create table sql_data_analysis as
select a.*,
	/* 1. 회원 프로파일 분석용 */
	date_format(a.join_date, '%Y-%m') as 가입연월,
    2021 - year(a.birthday) + 1 as 나이,
    case when 2021 - year(a.birthday) + 1 < 10 then '10대 이하'
		when 2021 - year(a.birthday) + 1 < 20 then '10대'
        when 2021 - year(a.birthday) + 1 < 30 then '20대'
        when 2021 - year(a.birthday) + 1 < 40 then '30대'
        when 2021 - year(a.birthday) + 1 < 50 then '40대'
	else '50대 이상' end as 연령대,
    case when c.mem_no is not null then '구매'
    else '미구매' end as 구매여부,
    
    
    /* 2. RFM 분석용 */
    b.구매금액 as 2020_구매금액,
    b.구매횟수 as 2020_구매횟수,
    case when b.구매금액 > 5000000 then 'VIP'
		when b.구매금액 > 1000000 or b.구매횟수 > 3 then '우수회원'
        when b.구매금액 > 0 then '일반회원'
        else '잠재회원' end as 2020_회원세분화,
       
       
	/* 3. 재구매율 및 구매주기 분석용 */
    case when date_add(c.최초구매일자, interval + 1 day) <= c.최근구매일자 then 'Y'
    else 'N' end as 재구매여부,
    datediff(c.최근구매일자, c.최초구매일자) as 구매간격,
    case when c.구매횟수-1 = 0 or datediff(c.최근구매일자, c.최초구매일자) = 0 then 0
    else datediff(c.최근구매일자, c.최초구매일자) / (c.구매횟수 - 1) end as 구매주기
    
from customer as a
left join (	
/* 1. RFM 분석용 (2020년 구매중 회원별 구매금액, 구매횟수)*/
    select a.mem_no,
		sum(a.sales_qty * b.price) as 구매금액, /* Monetary */
        count(a.order_no) as 구매횟수 /* Frequency */
	from sales as a
	left join product as b
	on a.product_code = b.product_code
    where year(a.order_date) = '2020' /* Recency */
	group by a.mem_no
    ) as b
on a.mem_no = b.mem_no
left join (
	/* 2. 재구매율 및 구매주기 분석용 (회원별 최초구매일자, 최근구매일자, 구매횟수)*/
	select mem_no,
		min(order_date) as 최초구매일자,
        max(order_date) as 최근구매일자,
        count(order_no) as 구매횟수
    from sales
    group by mem_no
    ) as c
on a.mem_no = c.mem_no;

/* 확인 */
select *
from sql_data_analysis;


/***************데이터 마트 정합성 체크***************/
select count(distinct mem_no), count(mem_no)
from sql_data_analysis;


/***************회원 프로파일 분석***************/
/* 1. 가입년월별 회원수 */
select 가입연월, count(mem_no) as 회원수
from sql_data_analysis
group by 가입연월;

/* 2. 성별 평균 연령 / 성별 및 연령대별 회원수 */
select gender as 성별, avg(나이) as 평균연령
from sql_data_analysis
group by gender;

select gender as 성별, 
	연령대, 
    count(mem_no) as 회원수
from sql_data_analysis
group by gender, 연령대
order by gender, 연령대;


/* 3. 성별 및 연령대별 회원수(+구매여부) */
select gender as 성별, 연령대, 구매여부, count(mem_no) as 회원수
from sql_data_analysis
group by gender, 연령대, 구매여부
order by 구매여부, gender, 연령대;

/***************RFM 분석***************/
/* 1. RFM 세분화별 회원수 */
select 2020_회원세분화, count(mem_no) as 회원수
from sql_data_analysis
group by 2020_회원세분화
order by 회원수 asc;


/* 2. RFM 세분화별 매출액 */
select 2020_회원세분화, sum(2020_구매금액) as 매출액
from sql_data_analysis
group by 2020_회원세분화
order by 매출액 desc;


/* 3. RFM 세분화별 인당 구매금액 */
select 2020_회원세분화, 
	sum(2020_구매금액) / count(mem_no) as 인당_구매금액
from sql_data_analysis
group by 2020_회원세분화
order by 인당_구매금액 desc;


/***************재구매율 및 구매주기 분석***************/

/* 1. 재구매 회원수 비중(%) */
select count(case when 구매여부 = '구매' then mem_no end) as 구매회원수,
	count(case when 재구매여부 = 'Y' then mem_no end) as 재구매회원수
from sql_data_analysis;


/* 2. 평균 구매주기 및 구매주기 구간별 회원수 */
select avg(구매주기)
from sql_data_analysis
where 구매주기 > 0;

select 구매주기_구간, count(mem_no) as 회원수
from (
	select *,
		case when 구매주기 <= 7 then '7일이내'
			when 구매주기 <= 14 then '14일이내'
			when 구매주기 <= 21 then '21일이내'
			when 구매주기 <= 28 then '28일이내'
		else '29일이후' end as 구매주기_구간
	from sql_data_analysis
) as a
group by 구매주기_구간;


/***************회원 프로파일 + RFM + 재구매율 및 구매주기 분석***************/

/* 1. RFM 세분화별 평균 나이 및 구매주기 */
select 2020_회원세분화, 
	avg(나이) as 평균_나이,
	avg(case when 구매주기 > 0 then 구매주기 end) as 평균_구매주기
from sql_data_analysis
group by 2020_회원세분화
order by 2020_회원세분화 asc;


/* 2. 연령대별 재구매 회원수 비중(%) */
select 연령대,
	count(case when 구매여부 = '구매' then mem_no end) as 구매회원수,
    count(case when 재구매여부 = 'Y' then mem_no end) as 재구매회원수
from sql_data_analysis
group by 연령대
order by 연령대 asc;


