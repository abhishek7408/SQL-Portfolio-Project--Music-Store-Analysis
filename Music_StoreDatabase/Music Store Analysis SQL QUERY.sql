--Project Title: Music Industry Database
--Created By: Abhishek Kumar Upadhyay
--Date of Creation: 01/03/2022
--Tools Used: PostgreSQL

--Question-(1)- Write a query to show tha data of each table.

SELECT * FROM Album;
SELECT * FROM Artist;
SELECT * FROM Customer;
SELECT * FROM Employee;
SELECT * FROM Genre;
SELECT * FROM Invoice;
SELECT * FROM Invoice_Line;
SELECT * FROM Media_Type;
SELECT * FROM Playlist;
SELECT * FROM Playlist_Track;
SELECT * FROM Track;

--Question-(2)- Who is the senior most employee based on job title?
SELECT CONCAT(First_name,'',Last_name) AS "Employee_Name", Title AS "Job_Title", Levels AS "Job_Levels"
FROM Employee
ORDER BY "Job_Levels" DESC
LIMIT 1;

--Question-(3)- Which countries have the most invoices?
SELECT Billing_Country AS Country, COUNT(Invoice_Id) AS Total_Invoice
FROM Invoice
GROUP BY Country
ORDER BY Total_Invoice DESC;

--Note: You can solve by another method
SELECT COUNT(*) AS Total_Invoice , Billing_Country
FROM Invoice
GROUP BY Billing_Country
ORDER BY Total_Invoice DESC;

--Question-(4)- What are the top three value of total invoice?
 SELECT Billing_Country, Total AS Total_Invoice_Value
 FROM Invoice
 ORDER BY Total_Invoice_Value DESC
 LIMIT 3;
 
/* Question-(5)- Which city has the best customers? We would like to throw a promotional Music Festival In the City we made the most
Money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & Sum of all invoice 
totals */
SELECT Billing_City AS City, SUM(Total) AS Invoice_Totals
FROM Invoice
GROUP BY City
ORDER BY Invoice_Totals DESC;

/* Question-(6)- Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query 
that returns the person who has spent the most money. */
SELECT Customer.Customer_Id, CONCAT(Customer.First_Name,'',Customer.Last_Name) AS Customer_Name, SUM(Invoice.Total) AS Total_Spent
FROM Customer AS Customer
LEFT JOIN Invoice AS Invoice
ON Customer.Customer_Id = Invoice.Customer_Id
GROUP BY Customer.Customer_Id, Customer_Name
ORDER BY Total_Spent DESC;

/* Question-(7)- Write query to return the email, first name and last name & Genere of all Rock Music listeners. Return your list 
ordered alphabetically by email starting with A */
SELECT DISTINCT email, First_name, Last_name
FROM Customer
JOIN Invoice ON Customer.Customer_id = Invoice.Customer_Id 
JOIN Invoice_line ON Invoice.Invoice_Id = Invoice_line.Invoice_Id
WHERE Track_id IN (
	SELECT Track_Id FROM Track
JOIN Genre ON Track.Genre_Id = Genre.Genre_Id
WHERE Genre.Name LIKE 'Rock'
	)
ORDER BY Email;

--Note You can solve this without subquery
SELECT DISTINCT Email, First_Name, Last_Name, Genre.Name AS Genre_Name
FROM Customer
JOIN Invoice ON Invoice.Customer_Id = Customer.Customer_Id
JOIN Invoice_Line ON Invoice_Line.Invoice_Id = Invoice.Invoice_Id
JOIN Track ON Track.Track_Id = Invoice_Line.Track_Id
JOIN Genre ON Genre.Genre_Id = Track.Genre_Id
WHERE Genre.Name LIKE 'Rock'
ORDER BY Email;
3

/* Question-(8)- Let's Invite the artist who have written the most rock music in our dataset. Write a query that returns the Artist name
and total track count of the top 10 rock bands. */
SELECT Artist.Artist_Id, Artist.Name, COUNT(Artist.Artist_Id) AS Number_of_Songs
FROM Track
JOIN Album ON Album.Album_Id = Track.Album_Id
JOIN Artist ON Artist.Artist_Id = Album.Artist_Id
JOIN Genre ON Genre.Genre_Id = Track.Genre_Id
WHERE Genre.Name LIKE 'Rock'
GROUP BY Artist.Artist_Id
ORDER BY Number_of_Songs DESC
LIMIT 10;

/* Question-(9)- Return the track names that have a song length longer than the average songs length. Return the Name and Milliseconds for 
each track. Order by the songs length with the longest songs listed first.*/ 
SELECT Name AS Track_Name, Milliseconds 
FROM Track
WHERE Milliseconds > (
	        SELECT AVG(Milliseconds) AS Avg_Track_Length
                  FROM Track)
ORDER BY Milliseconds DESC;	

/* Question-(10)- find how much amount spent by each customer on artists? write a query to return customer name, artist name and total
spent? */
WITH Best_Selling_Artist AS (
   SELECT Artist.Artist_Id, Artist.Name AS Artist_Name, SUM(Invoice_Line.Unit_Price*Invoice_Line.Quantity) AS Total_Sales
   FROM Invoice_Line
   JOIN Track ON Track.Track_Id = Invoice_Line.Track_Id
JOIN Album ON Album.Album_Id = Track.Album_Id
JOIN Artist ON Artist.Artist_Id = Album.Artist_Id
GROUP BY Artist.Artist_Id  -- You also can write GROUP BY 1 means Artist_id
ORDER BY Total_Sales DESC -- You also can write ORDER BY 3 means Total_Sales
	LIMIT 1 
) 
SELECT C.Customer_Id, C.First_Name, C.last_Name, Bsa.Artist_Name, SUM(Invoice_Line.Unit_Price*Invoice_Line.Quantity) AS Amount_Spent
FROM Invoice AS I
JOIN Customer AS C ON C.Customer_Id = I.Customer_Id
JOIN Invoice_line ON Invoice_Line.Invoice_Id = I.Invoice_Id
JOIN Track ON Track.Track_Id = Invoice_line.Track_Id
JOIN Album ON Album.Album_Id = Track.Album_Id
JOIN Best_Selling_Artist AS Bsa ON Bsa.Artist_Id = Album.Artist_Id
GROUP BY C.Customer_Id, C.First_Name, C.last_Name, Bsa.Artist_Name 
-- GROUP BY 1, 2, 3, 4 can also be used. As it indicates, C.Customer_Id, C.First_Name, C.Last_Name, and Bsa.Artist_Name
ORDER BY Amount_Spent DESC;

/* Question-(11)- We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with 
the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the Maximum number 
of purchases is shared return all Genres. */

--Method-1
WITH Popular_Genre AS (
SELECT COUNT(Invoice_Line.Quantity) AS Purchases, Customer.Country, Genre.Name AS Genre_Name, Genre.Genre_Id,
	ROW_NUMBER() OVER(PARTITION BY Customer.Country ORDER BY COUNT(Invoice_Line.Quantity)DESC) AS Row_No
	FROM Invoice_Line
	JOIN Invoice ON Invoice.Invoice_Id = Invoice_Line.Invoice_Id
	JOIN Customer ON Customer.Customer_Id = Invoice.Customer_Id
	JOIN Track ON Track.Track_Id = Invoice_Line.Track_Id
	JOIN Genre ON Genre.Genre_Id = Track.Genre_Id
	GROUP BY Customer.Country, Genre_Name, Genre.Genre_Id
	ORDER BY Customer.Country ASC, Purchases DESC	
)
SELECT * FROM Popular_Genre WHERE Row_No <=1;

--Method-2
WITH RECURSIVE
    Sales_Per_Country AS (
	SELECT COUNT(*) AS Purchase_Per_Genre, Customer.Country, Genre.Name, Genre.Genre_Id
	FROM Invoice_line
	JOIN Invoice ON Invoice.Invoice_Id = Invoice_Line.Invoice_Id
	JOIN Customer ON Customer.Customer_Id = Invoice.Customer_Id
	JOIN Track ON Track.Track_Id = Invoice_Line.Track_Id
	JOIN Genre ON Genre.Genre_Id = Track.Genre_Id
	GROUP BY Customer.Country, Genre.Name, Genre.Genre_Id
		ORDER BY Customer.Country
	),
	Max_Genre_Per_Country AS (SELECT MAX(Purchase_Per_Genre) AS Max_Genre_Number, Country
							 FROM Sales_Per_Country
							 GROUP BY Country
							 ORDER BY Country)
							 
SELECT Sales_Per_Country.*
FROM Sales_Per_Country
JOIN Max_Genre_Per_Country ON Sales_Per_Country.Country =Max_Genre_Per_Country.Country
WHERE Sales_Per_Country.Purchase_Per_Genre = Max_Genre_Per_Country.Max_Genre_Number;

/* Question-(12)- Write a query that determines the customer that has spent the most on music for each country. Write a query that returns
the country along with the top customers and how much they spent. For countries where the top amount spent is shared, provide all customers
who spent this amount.*/

--Method-1- With the use of CTE
WITH Customer_With_Country AS(
   SELECT Customer.Customer_Id, Customer.First_Name, Customer.Last_Name, Invoice.Billing_Country, SUM(Invoice.Total) AS Total_Spending,
  ROW_NUMBER() OVER(PARTITION BY Invoice.Billing_Country ORDER BY SUM(Invoice.Total) DESC) AS Row_Number
	FROM INVOICE
	JOIN Customer ON Customer.Customer_Id = Invoice.Customer_Id
	GROUP BY Customer.Customer_Id, Customer.First_Name, Customer.Last_Name, Invoice.Billing_Country
	ORDER BY Invoice.Billing_Country ASC, Total_Spending DESC
)
SELECT * FROM Customer_With_Country
  WHERE ROW_Number <=1;

--Method-2- With the use of RECURSIVE
WITH RECURSIVE 
    Customer_With_Country AS(
	SELECT Customer.Customer_Id, First_Name, Last_Name, Billing_Country, SUM(Total) AS Total_Spending
	FROM Invoice
	JOIN Customer ON Customer.Customer_Id = Invoice. Customer_Id
	GROUP BY Customer.Customer_Id, First_Name, Last_Name, Billing_Country
	ORDER BY First_Name, Last_Name DESC
	),
	Country_Max_Spending AS (
	SELECT Billing_Country, MAX(Total_Spending) AS Max_Spending
	FROM Customer_With_Country
	GROUP BY Billing_Country)
	
	SELECT Customer.Billing_Country, Customer.Total_Spending, Customer.First_Name, Customer.Last_Name, Customer.Customer_Id
	FROM Customer_With_Country AS Customer
	JOIN Country_Max_Spending AS CMS
	ON Customer.Billing_Country = CMS.Billing_Country
	WHERE Customer.Total_Spending = CMS.Max_Spending
	ORDER BY Customer.Billing_Country;