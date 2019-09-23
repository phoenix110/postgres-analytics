--
-- ボックス・ミュラー法(Box-Muller's method)による正規乱数の生成
--

--
-- 対数正規分布乱数
-- μ 元の正規分布の期待値
-- σ 元の正規分布の標準偏差
--
create or replace function random_lognormal(μ double precision, σ double precision)
returns double precision
as $$
  with ur(X, Y) as (select random(), random())
  -- 普通にボックス・ミュラーの一様乱数を指数化する
  select 
    exp(
      sqrt(-2 * ln(X)) * cos(2 * pi() * Y) * σ + μ
    ) 
  from ur;
$$ language sql;


-- 試行
select random_lognormal(μ := 0, σ := 1)
;
 random_lognormal 
------------------
 1.36994199458702
(1 row)

-- 検証
with
norm as (
  select n, random_lognormal(0, 1) as nd from generate_series(1,10000) as gs(n)
)
select n, nd as smpl, 
  avg(nd) over(order by n) as mean, 
  var_pop(nd) over (order by n) as variance
from norm 
;
/*
   n   |        smpl         |       mean       |     variance      
-------+---------------------+------------------+-------------------
     1 |    2.81250020573646 | 2.81250020573646 |                 0
     2 |   0.432207286634557 | 1.62235374618551 |  1.41644859518167
     3 |   0.240596163133887 |  1.1617678851683 |  1.36857773419237
     4 |    0.76455637379135 | 1.06246500732406 |  1.05601648528872
     5 |    1.39498995682466 | 1.12896999722418 | 0.862504842957435
     6 |    1.96153225718031 | 1.26773037388354 | 0.815026246451091
     7 |   0.426663441848477 | 1.14757795502139 | 0.785213548080062
     8 |    1.32128910041409 | 1.16929184819547 | 0.690362306667484
     9 |   0.364480454350674 |  1.0798683599905 | 0.677627865646397
    10 |   0.968676872829403 | 1.06874921127439 | 0.610977798295296
    11 |    1.32291110726734 | 1.09185483818284 | 0.560773062034957
    12 |    1.12208305234232 | 1.09437385602946 | 0.514111773492072
    13 |    1.23084623104514 | 1.10487173103067 | 0.475887178547173
    14 |   0.847800392756583 | 1.08650949258252 | 0.446278470633122
    15 |    1.35837582519105 | 1.10463391475642 | 0.421125498098844
    16 |   0.479002485308447 | 1.06553195041592 |  0.41773960869695
    17 |    5.33749214084636 | 1.31682372632359 |  1.40352759675962
    18 |    0.51160063305884 | 1.27208911003111 |  1.35957400159629
    19 |   0.361060735966851 | 1.22414024823825 |  1.32940115544664
    20 |    1.95297513054355 | 1.26058199235352 |  1.28816311124339
    21 |   0.714028258112369 | 1.23455562405632 |  1.24036944764282
    22 |    1.16300142004463 | 1.23130316023761 |  1.18421116714324
    23 |    1.29713103730946 | 1.23416524184943 |   1.1329039383389
    24 |   0.309703218583603 | 1.19564599088002 |  1.11982545956539
     :
  9990 |   0.112336521172201 | 1.63212831192926 |  4.13147140581362
  9991 |   0.948375651516277 | 1.63205987507004 |  4.13110467570662
  9992 |   0.891603704624894 | 1.63198577016908 |  4.13074610042571
  9993 |   0.608717198050963 | 1.63188337163289 |  4.13043750717935
  9994 |     1.1431890301909 | 1.63183447285948 |  4.13004810961637
  9995 |    0.77032571060287 | 1.63174827888627 |  4.12970914763348
  9996 |    1.17206639597041 | 1.63170229230334 |  4.12931714854851
  9997 |    0.56053871459956 | 1.63159514380102 |  4.12901885500925
  9998 |    4.26871151034182 | 1.63185890819055 |  4.12930137834375
  9999 |   0.658876207331723 | 1.63176160018967 |  4.12898307644144
 10000 |    1.03891491993087 | 1.63170231552164 |  4.12860532133775
(10000 rows)
*/


-- ヒストグラム
with
lognorm as (
  select n, random_lognormal(0, 1) as nd from generate_series(1,10000) as gs(n)
),
hist as (
  select floor(nd*10)/10 as bin, count(nd) as cnt
  from lognorm group by bin order by bin
)
select bin,
  cnt::double precision / sum(cnt) over() as density,
  repeat('*',((cnt/sum(cnt) over())*1000)::int) as bar
from hist
;
/*
 bin  | density |                                   bar                                   
------+---------+-------------------------------------------------------------------------
    0 |  0.0121 | ************
  0.1 |  0.0381 | **************************************
  0.2 |  0.0623 | **************************************************************
  0.3 |  0.0708 | ***********************************************************************
  0.4 |   0.063 | ***************************************************************
  0.5 |  0.0597 | ************************************************************
  0.6 |  0.0581 | **********************************************************
  0.7 |   0.052 | ****************************************************
  0.8 |   0.043 | *******************************************
  0.9 |   0.041 | *****************************************
    1 |  0.0373 | *************************************
  1.1 |  0.0342 | **********************************
  1.2 |  0.0334 | *********************************
  1.3 |  0.0273 | ***************************
  1.4 |  0.0256 | **************************
  1.5 |  0.0229 | ***********************
  1.6 |  0.0182 | ******************
  1.7 |  0.0191 | *******************
  1.8 |  0.0177 | ******************
  1.9 |  0.0154 | ***************
    2 |  0.0174 | *****************
  2.1 |  0.0146 | ***************
  2.2 |  0.0122 | ************
  2.3 |  0.0106 | ***********
  2.4 |  0.0119 | ************
  2.5 |  0.0116 | ************
  2.6 |  0.0114 | ***********
  2.7 |  0.0093 | *********
  2.8 |  0.0085 | *********
  2.9 |  0.0081 | ********
    3 |  0.0075 | ********
  3.1 |  0.0059 | ******
  3.2 |  0.0067 | *******
  3.3 |  0.0054 | *****
  3.4 |  0.0059 | ******
  3.5 |  0.0056 | ******
  3.6 |  0.0052 | *****
  3.7 |  0.0029 | ***
  3.8 |  0.0035 | ****
  3.9 |  0.0038 | ****
    4 |  0.0048 | *****
  4.1 |   0.003 | ***
  4.2 |  0.0034 | ***
  4.3 |  0.0026 | ***
  4.4 |  0.0019 | **
  4.5 |   0.003 | ***
  4.6 |   0.003 | ***
  4.7 |  0.0026 | ***
  4.8 |  0.0026 | ***
  4.9 |  0.0027 | ***
    5 |  0.0024 | **
  5.1 |  0.0021 | **
  5.2 |   0.002 | **
  5.3 |  0.0016 | **
  5.4 |  0.0016 | **
  5.5 |  0.0014 | *
  5.6 |  0.0017 | **
  5.7 |  0.0015 | **
  5.8 |  0.0018 | **
  5.9 |  0.0013 | *
    6 |  0.0008 | *
  6.1 |   0.001 | *
  6.2 |  0.0013 | *
  6.3 |  0.0009 | *
  6.4 |  0.0014 | *
  6.5 |  0.0006 | *
  6.6 |  0.0008 | *
  6.7 |  0.0008 | *
  6.8 |   0.001 | *
  6.9 |  0.0004 | 
    7 |  0.0007 | *
  7.1 |  0.0009 | *
  7.2 |   0.001 | *
  7.3 |  0.0008 | *
  7.4 |  0.0005 | *
  7.5 |  0.0004 | 
  7.6 |  0.0006 | *
  7.7 |  0.0004 | 
  7.8 |  0.0008 | *
  7.9 |  0.0007 | *
    8 |   0.001 | *
  8.1 |  0.0007 | *
  8.2 |  0.0006 | *
  8.3 |  0.0007 | *
  8.4 |  0.0002 | 
  8.5 |  0.0004 | 
  8.6 |  0.0002 | 
  8.7 |  0.0005 | *
  8.8 |  0.0007 | *
    9 |  0.0005 | *
  9.1 |  0.0004 | 
  9.2 |  0.0005 | *
  9.3 |  0.0005 | *
  9.4 |  0.0001 | 
  9.5 |  0.0005 | *
  9.6 |  0.0001 | 
  9.7 |  0.0006 | *
  9.8 |  0.0003 | 
  9.9 |  0.0002 | 
   10 |  0.0002 | 
 10.1 |  0.0003 | 
 10.2 |  0.0003 | 
 10.3 |  0.0001 | 
 10.4 |  0.0002 | 
 10.5 |  0.0004 | 
 10.8 |  0.0002 | 
 10.9 |  0.0002 | 
   11 |  0.0001 | 
 11.1 |  0.0001 | 
 11.2 |  0.0001 | 
 11.3 |  0.0001 | 
 11.4 |  0.0002 | 
 11.5 |  0.0001 | 
 11.6 |  0.0001 | 
 11.7 |  0.0001 | 
 11.8 |  0.0001 | 
 11.9 |  0.0002 | 
   12 |  0.0003 | 
 12.1 |  0.0001 | 
 12.2 |  0.0001 | 
 12.3 |  0.0001 | 
 12.4 |  0.0004 | 
 12.5 |  0.0001 | 
 12.7 |  0.0002 | 
 12.8 |  0.0001 | 
 12.9 |  0.0001 | 
 13.1 |  0.0001 | 
 13.2 |  0.0002 | 
 13.4 |  0.0003 | 
 13.5 |  0.0001 | 
 13.6 |  0.0001 | 
 13.8 |  0.0002 | 
 13.9 |  0.0001 | 
   14 |  0.0002 | 
 14.3 |  0.0001 | 
 14.4 |  0.0002 | 
 14.7 |  0.0002 | 
 14.8 |  0.0001 | 
 14.9 |  0.0001 | 
 15.3 |  0.0001 | 
 16.1 |  0.0001 | 
 16.3 |  0.0001 | 
 16.5 |  0.0001 | 
 17.1 |  0.0001 | 
 17.3 |  0.0003 | 
 17.7 |  0.0001 | 
 17.8 |  0.0001 | 
 18.1 |  0.0001 | 
 18.5 |  0.0001 | 
 18.6 |  0.0001 | 
 19.9 |  0.0001 | 
 20.6 |  0.0001 | 
 20.8 |  0.0001 | 
   22 |  0.0001 | 
 22.7 |  0.0001 | 
 22.9 |  0.0001 | 
 23.3 |  0.0001 | 
 23.5 |  0.0001 | 
 25.4 |  0.0001 | 
 27.6 |  0.0001 | 
 39.1 |  0.0001 | 
 41.8 |  0.0001 | 
 44.8 |  0.0001 | 
   50 |  0.0001 | 
(164 rows)
*/
-- 後始末
drop function if exists norm_bm;
