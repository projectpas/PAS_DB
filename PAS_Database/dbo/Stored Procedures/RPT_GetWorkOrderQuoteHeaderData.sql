/*************************************************************             
 ** File:   [RPT_GetWorkOrderQuoteHeaderData]             
 ** Author:   AMIT GHEDIYA  
 ** Description: This stored procedure is used to get work order quote pdf header details  
 ** Purpose:           
 ** Date:   01/05/2024          
            
 ** PARAMETERS:   
 ** RETURN VALUE:             
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    01/05/2024   AMIT GHEDIYA		Created  
    2    02/05/2024   VISHAL SUTHAR		Modified to fix WOQ Print issues

--EXEC [RPT_GetWorkOrderQuoteHeaderData] 2174
**************************************************************/  
CREATE         PROCEDURE [dbo].[RPT_GetWorkOrderQuoteHeaderData]  
 @WorkOrderQuoteId bigint 
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
		SELECT TOP 1  
			woq.WorkOrderQuoteId,
            wo.WorkOrderId,
            QuoteNumber = UPPER(woq.QuoteNumber),
            woq.OpenDate,
            woq.QuoteDueDate,
            woq.ValidForDays,
            woq.ExpirationDate,
            wo.CustomerContactId,
            QuoteStatus = wqs.[Description],
            WorkOrderNum = UPPER(wo.WorkOrderNum),
            CustomerName = UPPER(cust.[Name]),
			TAXRates = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId and t.Code ='SALES TAX'
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
			Othertax = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId 
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
            CustomerId = cust.[CustomerId],
            cust.CustomerCode,
			CustomerContact = con.FirstName + ' ' + con.LastName,
            Title = con.ContactTitle,
            WorkPhone = con.WorkPhone + ' ' + con.WorkPhoneExtn,
			Phone = UPPER(ISNULL(con.WorkPhone,'')),
            Email = UPPER(ISNULL(con.Email,'')),
            Address1 = UPPER(ISNULL(adr.Line1,'')),
            Address2 = UPPER(ISNULL(adr.Line2,'')),
			ComboAddress = UPPER(ISNULL(adr.Line1,'')) + (CASE WHEN ISNULL(adr.Line2, '') = '' THEN '' ELSE (', ' + UPPER(ISNULL(adr.Line2,''))) END),
            City = UPPER(ISNULL(adr.City,'')),
            State = UPPER(ISNULL(adr.StateOrProvince,'')),
			ComboCitystate = UPPER(ISNULL(adr.City,'')) + ' ' + UPPER(ISNULL(adr.StateOrProvince,'')),
			ComboCitystateZip = UPPER(ISNULL(adr.City,'')) + 
				CASE WHEN ISNULL(adr.StateOrProvince, '') = '' THEN '' ELSE (', ' + UPPER(ISNULL(adr.StateOrProvince,''))) END + 
				(CASE WHEN ISNULL(adr.PostalCode,'') = '' THEN '' ELSE ', ' + UPPER(ISNULL(adr.PostalCode,'')) END),
            Zip = UPPER(ISNULL(adr.PostalCode,'')),
            Country = UPPER(ISNULL(co.countries_name,'')),
            ShipVia = UPPER(ISNULL(cs.ShipVia,'')),
            CustomerEmail = cust.Email,
            cust.CustomerPhone,
            CustomerRef = cust.ContractReference,
            ARBalance = woq.AccountsReceivableBalance,
            CreditLimit = ISNULL(cf.CreditLimit,0),
            CreditTerms = UPPER(ISNULL(ct.Name,'')),
            SalesPerson = UPPER(ISNULL(sp.FirstName,'') + ' ' + ISNULL(sp.LastName,'')),
            CSR = ISNULL(csr.FirstName,'') + ' ' + ISNULL(csr.LastName,''),
            Employee = ISNULL(emp.FirstName,'') + ' ' + ISNULL(emp.LastName,''),
            VersionNo = UPPER(woq.VersionNo),
            CreatedBy = UPPER(woq.CreatedBy),
            sa.SiteName,
            Currency = cur.Code,
            wop.ManagementStructureId,
            woq.Memo,
            woq.QuoteStatusId,
            TaxRate = ISNULL(custtax.TaxRate,0),
            CustomerAttention = sa.Attention,
            WONotes = woq.Notes,
            WOCustomerRef = UPPER(wop.CustomerReference),
			WorkScope = UPPER(wop.WorkScope)
			 FROM dbo.WorkOrderQuote woq WITH(NOLOCK)
			 INNER JOIN dbo.WorkOrder wo WITH(NOLOCK) ON woq.WorkOrderId = wo.WorkOrderId
			 INNER JOIN dbo.WorkOrderPartNumber wop WITH(NOLOCK)  ON woq.WorkOrderId = wop.WorkOrderId
			 INNER JOIN dbo.WorkOrderQuoteStatus wqs WITH(NOLOCK)  ON woq.QuoteStatusId = wqs.WorkOrderQuoteStatusId
			 INNER JOIN dbo.Customer cust WITH(NOLOCK)  ON woq.CustomerId = cust.CustomerId
			 LEFT JOIN dbo.CustomerSales css WITH(NOLOCK)  ON cust.CustomerId = css.CustomerId
			 LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK)  ON cust.CustomerId = cf.CustomerId 
			 INNER JOIN dbo.Currency cur WITH(NOLOCK)  ON woq.CurrencyId = cur.CurrencyId
			 LEFT JOIN dbo.CreditTerms ct WITH(NOLOCK)  ON cf.CreditTermsId = ct.CreditTermsId
			 LEFT JOIN dbo.Employee sp WITH(NOLOCK)  ON wo.SalesPersonId = sp.EmployeeId
			 LEFT JOIN dbo.Employee csr WITH(NOLOCK)  ON css.PrimarySalesPersonId = csr.EmployeeId
			 LEFT JOIN dbo.Employee emp WITH(NOLOCK)  ON wo.EmployeeId = emp.EmployeeId
			 LEFT JOIN dbo.CustomerContact cc WITH(NOLOCK)  ON wo.CustomerContactId = cc.CustomerContactId
			 LEFT JOIN dbo.Contact con WITH(NOLOCK)  ON cc.ContactId = con.ContactId
			 LEFT JOIN dbo.Address adr WITH(NOLOCK)  ON cust.AddressId = adr.AddressId
			 LEFT JOIN dbo.Countries co WITH(NOLOCK)  ON adr.CountryId = co.countries_id
			 LEFT JOIN dbo.CustomerDomensticShipping sa WITH(NOLOCK)  ON cust.CustomerId = sa.CustomerId AND sa.IsPrimary = 1
			 LEFT JOIN dbo.CustomerDomensticShippingShipVia cs WITH(NOLOCK)  ON cust.CustomerId = cs.CustomerId AND cs.IsPrimary = 1
			 LEFT JOIN dbo.ShippingVia sv WITH(NOLOCK)  ON cs.ShipViaId = sv.ShippingViaId 
			 LEFT JOIN dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)  ON cust.CustomerId = custtax.CustomerId
		WHERE woq.IsDeleted = 0 AND woq.WorkOrderQuoteId = @WorkOrderQuoteId

   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetWorkOrderQuoteHeaderData'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        = @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END