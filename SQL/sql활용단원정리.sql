use practice;

/* 1. CUSTOMER 테이블을 활용하여, 가입일자가 2019년이며 생일이 4~6월생인 회원수를 조회하시오.*/
select count(distinct a.mem_no) as 회원수
from 
(
select *
	, year(join_date) as 가입년도
	, month(birthday) as 생일월
from customer
where year(join_date) = '2019' and (month(birthday) between 4 and 6)
) as a;

SELECT  COUNT(MEM_NO)
  FROM  CUSTOMER
 WHERE  YEAR(JOIN_DATE) = 2019
   AND  MONTH(BIRTHDAY) BETWEEN 4 AND 6;

/* 2. SALES 및 PRODUCT 테이블을 활용하여, 1회 주문시 평균 구매금액를 구하시오.(비회원 9999999 제외)*/
select avg(a.sales_qty * b.price) as 평균_구매금액,
	sum(a.sales_qty * b.price) / count(a.order_no) as 1회_주문시_구매금액
from sales as a
left join product as b
on a.product_code = b.product_code
where a.mem_no <> '9999999';


/* 3. SALES 테이블을 활용하여, 구매수량이 높은 상위 10명을 조회하시오.(비회원 9999999 제외)*/

select *
from( 
select mem_no, 
	sum(sales_qty) as 구매수량,
    row_number() over (order by sum(sales_qty) desc) as 순위
from sales
where mem_no <> '9999999'
group by mem_no
) as a 
where 순위 <= 10;


/***************View 및 Procedure***************/
/* 1. View를 활용하여, Sales 테이블 기준으로 CUSTOMER 및 PRODUCT 테이블을 LEFT JOIN 결합한 가상 테이블을 생성하시오.*/
/* 열은 SALES 테이블의 모든 열 + CUSTOMER 테이블의 GENDER + PRODUCT 테이블의 BRAND*/

create view sales_gender_brand as
select a.*,
	b.gender, c.brand
from sales as a
left join customer as b
on a.mem_no = b.mem_no
left join product as c
on a.product_code = c.product_code;

/* 확인 */
select *
from sales_gender_brand;


/* 2. Procedure를 활용하여, CUSTOMER의 몇월부터 몇월까지의 생일인 회원을 조회하는 작업을 저장하시오.*/
delimiter //
create procedure cst_birth_month_in (in input_a int, input_b int)
begin select *
	from customer
    where month(birthday) between input_a and input_b;
end //
delimiter ;

/* 확인 */
call cst_birth_month_in(4, 6);


/***************데이터 마트***************/

/* 1. SALES 및 PRODUCT 테이블을 활용하여, SALES 테이블 기준으로 PRODUCT 테이블을 LEFT JOIN 결합한 테이블을 생성하시오.*/
/* 열은 SALES 테이블의 모든 열 + PRODUCT 테이블의 CATEGORY, TYPE + SALES_QTY * PRICE 구매금액 */

create table sales_mart as
select a.*, b.category, b.type,
	a.sales_qty * b.price as 구매금액	
from sales as a
left join product as b
on a.product_code = b.product_code;

/* 확인 */
select *
from sales_mart;


/* 2. (1)에서 생성한 데이터 마트를 활용하여, CATEGORY 및 TYPE별 구매금액 합계를 구하시오*/
select category, type, sum(구매금액) as 총구매금액
from sales_mart
group by category, type;


