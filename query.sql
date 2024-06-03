/* 
RAKAMIN X KIMIA FARMA - BIG DATA ANALYTICS - VIRTUAL INTERNSHIP MAY 2024
Code created by: Hikmawati Fajriah Ayu Wardana
*/

/* check apakah kolom "product_name" di tabel kf_inventory sama dengan "product_name" di tabel kf_product */
SELECT 
  a.product_name, b.product_name 
FROM 
  `rakamin-kf-analytics-424807.kimia_farma.kf_inventory` AS a
JOIN
  `rakamin-kf-analytics-424807.kimia_farma.kf_product` AS b
ON a.product_id=b.product_id
LIMIT 1000;

-- hasil: sama, sehingga kolom yang diambil untuk dianalisis adalah kolom product_name dari tabel produk (kf_product)



/* check apakah kolom "price" di tabel kf_final_transaction sama dengan "price" di tabel kf_product */
SELECT 
  a.price, b.price 
FROM 
  `rakamin-kf-analytics-424807.kimia_farma.kf_final_transaction` AS a
JOIN
  `rakamin-kf-analytics-424807.kimia_farma.kf_product` AS b
ON a.product_id=b.product_id
LIMIT 1000;

-- hasil: sama, sehingga kolom yang diambil untuk dianalisis adalah kolom price dari tabel produk (kf_product)



/* cek apakah bisa terjadi transaksi ketika stok produk = 0  */
SELECT 
  t.transaction_id,
  t.product_id,
  t.branch_id,
  i.opname_stock
FROM 
    `rakamin-kf-analytics-424807.kimia_farma.kf_final_transaction` t
JOIN 
    `rakamin-kf-analytics-424807.kimia_farma.kf_inventory` i
ON 
    t.product_id=i.product_id AND t.branch_id=i.branch_id
WHERE
  i.opname_stock=0
LIMIT 100;

-- hasil: bisa [tambahan: asumsinya karena stok produk pada tabel kf_inventory pernah tersedia pada saat pembelian berlangsung], 
-- sehingga data pada tabel kf_final_transaction lebih utama ketika melakukan join dengan tabel kf_inventory 



/* ============================== QUERY UNTUK MEMBUAT TABEL ANALISIS ============================== */

CREATE TABLE `rakamin-kf-analytics-424807.kimia_farma.kf_performance` AS
WITH gross_profit AS -- membuat tabel sementara bernama gross_profit untuk menghitung persentase_gross_laba
  (SELECT
    product_id,
    (CASE
      WHEN price <= 50000 THEN 0.10
      WHEN price > 50000 AND price <= 100000 THEN 0.15
      WHEN price > 100000 AND price <= 300000 THEN 0.20
      WHEN price > 300000 AND price <= 500000 THEN 0.25
      ELSE 0.30
    END) AS persentase_gross_laba
  FROM `rakamin-kf-analytics-424807.kimia_farma.kf_product`
  )
SELECT DISTINCT -- query menggunakan distinct, karena ketika tabel kf_final_transaction di-join dengan kf_inventory menghasilkan data duplikat 
  t.transaction_id,
  t.date,
  t.branch_id,
  c.branch_name,
  c.kota,
  c.provinsi,
  c.rating AS rating_cabang,
  t.customer_name,
  t.product_id,
  p.product_name,
  p.product_category, -- additional, jika memungkinkan dapat dianalisis pada dashboard
  p.price AS actual_price,
  t.discount_percentage,
  g.persentase_gross_laba, -- menggunakan kolom dari tabel sementara yang telah dibuat
  p.price * (1-t.discount_percentage) AS nett_sales, -- nett sales: harga produk yang telah dipotong diskon
  g.persentase_gross_laba * (p.price * (1-t.discount_percentage)) AS nett_profit, -- nett profit: persentase gross laba dikali harga produk yang sudah diskon
  t.rating AS rating_transaksi,
  i.opname_stock -- additional, jika memungkinkan dapat dianalisis pada dashboard
FROM
  `rakamin-kf-analytics-424807.kimia_farma.kf_final_transaction` AS t
JOIN
  `rakamin-kf-analytics-424807.kimia_farma. kf_kantor_cabang` AS c
ON 
  t.branch_id=c.branch_id
JOIN
  `rakamin-kf-analytics-424807.kimia_farma.kf_product` AS p
ON 
  t.product_id=p.product_id
LEFT JOIN
  `rakamin-kf-analytics-424807.kimia_farma.kf_inventory` AS i
ON
  t.branch_id=i.branch_id AND t.product_id=i.product_id
JOIN
  gross_profit AS g
ON
  t.product_id=g.product_id
;
/* ============================== END OF QUERY UNTUK MEMBUAT TABEL ANALISIS ============================== */



/* additional query untuk membantu keperluan diagnostic analytics pada dashboard */
-- query untuk menentukan jumlah setiap kategori cabang
SELECT 
  branch_category, 
  COUNT(branch_category) AS jumlah_cabang
FROM 
  `rakamin-kf-analytics-424807.kimia_farma. kf_kantor_cabang` 
GROUP BY 1;
