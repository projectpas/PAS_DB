/*************************************************************           
 ** File:   [AutoCompleteDropdownsCustomer]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Customer List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   12/23/2020        
 
 ** PARAMETERS: @UserType varchar(60)   
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/23/2020   Hemant Saliya Created
	1    05/05/2020   Hemant Saliya Added Try-catch & Content Managment
     
-- EXEC [AutoCompleteDropdownsCustomer] '',1,25,'0',1,1
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsCustomer]
@StartWith VARCHAR(50),
@IsActive bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int,
@customerType int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		--BEGIN TRANSACTION
			--BEGIN
				DECLARE @Sql NVARCHAR(MAX);	
				IF(@Count = '0') 
				   BEGIN
				   set @Count='20';	
				END	
				IF(@customerType = 1)
				BEGIN
					IF(@IsActive = 1)
					BEGIN		
							SELECT DISTINCT TOP 20 
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn AS CustomerPhoneNo,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H 
							WHERE (c.IsActive = 1 AND ISNULL(c.IsDeleted, 0) = 0 AND c.MasterCompanyId = @MasterCompanyId  AND (c.Name LIKE  '%'+ @StartWith + '%'))    -- AND (c.CustomerAffiliationId = 2 OR c.CustomerAffiliationId = 3)
					   UNION     
							SELECT DISTINCT
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON  con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H 
							WHERE c.CustomerId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
						ORDER BY CustomerName				
					End
					ELSE
					BEGIN
						SELECT DISTINCT TOP 20 
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H
						WHERE c.IsActive = 1 AND ISNULL(c.IsDeleted,0) = 0 AND (c.CustomerAffiliationId = 2 OR c.CustomerAffiliationId = 3) AND c.MasterCompanyId = @MasterCompanyId AND (c.Name LIKE '%' + @StartWith + '%' OR c.Name  LIKE '%' + @StartWith + '%')
						UNION 
						SELECT DISTINCT TOP 20 
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H
						WHERE c.CustomerId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
						ORDER BY CustomerName	
					END
				END
				ELSE IF(@customerType = 2)
				BEGIN
					IF(@IsActive = 1)
					BEGIN		
							SELECT DISTINCT TOP 20 
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn AS CustomerPhoneNo,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H
							WHERE (c.IsActive = 1 AND ISNULL(c.IsDeleted, 0) = 0 AND c.MasterCompanyId = @MasterCompanyId AND c.CustomerAffiliationId = 1 AND (c.Name LIKE '%'+ @StartWith + '%' ))    
					   UNION     
							SELECT DISTINCT
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H
							WHERE c.CustomerId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
						ORDER BY CustomerName				
					End
					ELSE
					BEGIN
						SELECT DISTINCT TOP 20 
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H
						WHERE c.IsActive=1 AND ISNULL(c.IsDeleted, 0) = 0 AND c.CustomerAffiliationId = 1 AND c.MasterCompanyId = @MasterCompanyId AND (c.Name LIKE '%' + @StartWith + '%' OR c.Name  LIKE '%' + @StartWith + '%')
						UNION 
						SELECT DISTINCT TOP 20 
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H
						WHERE c.CustomerId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
						ORDER BY CustomerName	
					END
				END
				ELSE
				BEGIN
					IF(@IsActive = 1)
					BEGIN		
							SELECT DISTINCT TOP 20 
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn AS CustomerPhoneNo,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
								( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
								) H
							WHERE (c.IsActive = 1 AND ISNULL(c.IsDeleted, 0) = 0 AND c.MasterCompanyId = @MasterCompanyId AND (c.Name LIKE '%'+ @StartWith + '%' ))    
					   UNION     
							SELECT DISTINCT
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H
							WHERE c.CustomerId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
						ORDER BY CustomerName				
					End
					ELSE
					BEGIN
						SELECT DISTINCT TOP 20 
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H
						WHERE c.IsActive = 1 AND ISNULL(c.IsDeleted, 0) = 0 AND c.MasterCompanyId = @MasterCompanyId AND (c.Name  LIKE '%' + @StartWith + '%')
						UNION 
						SELECT DISTINCT TOP 20 
								c.CustomerId,
								c.CustomerCode,
								c.ContractReference AS CustomerRef,
								c.Name AS CustomerName,
								cf.CreditLimit,
								cf.CreditTermsId,
								con.FirstName + ' ' + con.LastName AS CustomerContact,
								e.FirstName AS CSRName,
								c.Email AS CustomerEmail,
								con.WorkPhone + ' ' + con.WorkPhoneExtn,
								cs.CsrId AS CSRId,
								cs.PrimarySalesPersonId AS SalesPersonId,
								emp.FirstName AS SalesPerson,
								ct.Name CreditTerm,
								c.RestrictPMA,
								c.RestrictDER,
								ISNULL(H.ARBalance,0) as ARBalance
							FROM dbo.Customer c WITH(NOLOCK)
								LEFT JOIN dbo.CustomerSales cs WITH(NOLOCK) ON c.CustomerId =  cs.CustomerId
								LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON c.CustomerId =  cf.CustomerId
								LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK) ON c.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
								LEFT JOIN dbo.Contact con WITH(NOLOCK) ON con.ContactId = cc.ContactId
								LEFT JOIN dbo.Employee e WITH(NOLOCK) ON e.EmployeeId = cs.CsrId
								LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON emp.EmployeeId = cs.PrimarySalesPersonId
								LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
								OUTER APPLY 
									( 
									SELECT top 1 ARBalance FROM CustomerCreditTermsHistory cch WITH(NOLOCK)
									WHERE c.CustomerId = cch.CustomerId order by CustomerCreditTermsHistoryId desc
									) H
						WHERE c.CustomerId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
						ORDER BY CustomerName	
					END
				END
		END TRY    
		BEGIN CATCH      
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
               , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsCustomer' 
			   , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))  
			   + '@Parameter5 = ''' + CAST(ISNULL(@customerType, '') as varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName        = @DatabaseName
                     , @AdhocComments       = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName     =  @ApplicationName
                     , @ErrorLogID          = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END