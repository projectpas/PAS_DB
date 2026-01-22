/*************************************************************           
 ** File:   [sp_GetCustomerInvoicedatabyInvoiceId]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer Invoicedataby InvoiceId   
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author				Change Description            
 ** --   --------		 -------			--------------------------------          
    1    04/18/2022		Subhash Saliya		Created
	2	 02/1/2024		AMIT GHEDIYA		added isperforma Flage for SO
	3	 04/19/2024		Devendra Shekh		added data for Exchange SO
	4	 04/19/2024		Devendra Shekh		modified for invoiceTypeId changes
	5    11/04/2024		Vishal Suthar		Modified to make use of new SO Part tables
	6	 21-Mar-2025	Divyesh Kathiriya	Update InvoiceDate based on Employee time zone
	7	 06-June-2025	AMIT GHEDIYA		Get WO/SO Billing data from new table.

 -- exec sp_GetCustomerInvoicedatabyInvoiceId 124,0,3,226    
**************************************************************/ 

CREATE    PROCEDURE [dbo].[sp_GetCustomerInvoicedatabyInvoiceId]
@InvoicingId BIGINT,
@isWorkOrder BIT,
@InvoiceTypeId INT,
@EmployeeId BIGINT
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 

			Declare @WOInvoiceTypeId INT = 0;
			Declare @SOInvoiceTypeId INT = 0;
			Declare @ExchangeInvoiceTypeId INT = 0;

			SELECT @WOInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDER';
			SELECT @SOInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'SALESORDER';
			SELECT @ExchangeInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'EXCHANGE';

			DECLARE @workOrderModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrder');
			DECLARE @salesOrderModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder');
			
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

			IF(@InvoiceTypeId = @SOInvoiceTypeId)
			BEGIN

				SELECT SOBI.BillingInvoicingId as InvoiceId,SOBI.InvoiceNo [InvoiceNo],
				SOBI.InvoiceStatus [InvoiceStatus],
				--SOBI.InvoiceDate [InvoiceDate],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				   CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			    ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				SO.SalesOrderNumber [OrderNumber],
				C.Name [CustomerName],CT.CustomerTypeName [CustomerType],
				SOBI.GrandTotal [InvoiceAmt],
				IsWorkOrder=0,
				SOBI.ReferenceId AS [ReferenceId]
				,(CON.FirstName +' '+ CON.LastName +' - '+ CON.WorkPhone) as ContactInfo
			    ,SO.CustomerContactId as  CustomerContactId
			   ,RMAC.RMAReasonId
			   ,RMAC.RMAReason
			   ,RMAC.RMAStatusId
			   ,RMAC.RMAStatus
			   ,RMAC.ValidDays
			   ,SOBI.MasterCompanyId
			   ,C.CustomerId
			   ,c.CustomerCode
			   ,SO.ManagementStructureId as ManagementStructureId
			   ,'0' as AddressCount
			   ,'0' as PartCount
			   ,@SOInvoiceTypeId AS 'InvoiceTypeId'
			FROM [dbo].BillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN [dbo].SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.ReferenceId
				LEFT JOIN [dbo].SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
				LEFT JOIN [dbo].Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				LEFT JOIN [dbo].CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN [dbo].CustomerContact CUN WITH (NOLOCK) ON CUN.CustomerContactId=SO.CustomerContactId
				LEFT JOIN [dbo].Contact CON WITH (NOLOCK) ON CON.ContactId=CUN.ContactId
				LEFT JOIN [dbo].RMACreditMemoSettings RMAC WITH (NOLOCK) ON so.MasterCompanyId = RMAC.MasterCompanyId
			    Where SOBI.BillingInvoicingId=@InvoicingId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0	AND SOBI.ModuleId = @salesOrderModuleId

			END
			ELSE IF(@InvoiceTypeId = @ExchangeInvoiceTypeId)
			BEGIN

				SELECT ESOBI.SOBillingInvoicingId as InvoiceId,ESOBI.InvoiceNo [InvoiceNo],
				ESOBI.InvoiceStatus [InvoiceStatus],
				--ESOBI.InvoiceDate [InvoiceDate],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				   CASE WHEN CAST(ESOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ESOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			    ELSE (CAST(ESOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				ESO.ExchangeSalesOrderNumber [OrderNumber],
				C.Name [CustomerName],CT.CustomerTypeName [CustomerType],
				ESOBI.GrandTotal [InvoiceAmt],
				IsWorkOrder = 0,
				ESOBI.ExchangeSalesOrderId AS [ReferenceId]
				,(CON.FirstName +' '+ CON.LastName +' - '+ CON.WorkPhone) as ContactInfo
			    ,ESO.CustomerContactId as  CustomerContactId
			   ,RMAC.RMAReasonId
			   ,RMAC.RMAReason
			   ,RMAC.RMAStatusId
			   ,RMAC.RMAStatus
			   ,RMAC.ValidDays
			   ,ESOBI.MasterCompanyId
			   ,C.CustomerId
			   ,c.CustomerCode
			   ,ESO.ManagementStructureId as ManagementStructureId
			   ,'0' as AddressCount
			   ,'0' as PartCount
			   ,@ExchangeInvoiceTypeId AS 'InvoiceTypeId'
			FROM [dbo].ExchangeSalesOrderBillingInvoicing ESOBI WITH (NOLOCK)
				LEFT JOIN [dbo].ExchangeSalesOrderPart ESOPN WITH (NOLOCK) ON ESOPN.ExchangeSalesOrderId = ESOBI.ExchangeSalesOrderId
				LEFT JOIN [dbo].Customer C WITH (NOLOCK) ON ESOBI.CustomerId = C.CustomerId
				LEFT JOIN [dbo].ExchangeSalesOrder ESO WITH (NOLOCK) ON ESOBI.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId
				LEFT JOIN [dbo].CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN [dbo].CustomerContact CUN WITH (NOLOCK) ON CUN.CustomerContactId = ESO.CustomerContactId
				LEFT JOIN [dbo].Contact CON WITH (NOLOCK) ON CON.ContactId=CUN.ContactId
				LEFT JOIN [dbo].RMACreditMemoSettings RMAC WITH (NOLOCK) ON ESO.MasterCompanyId = RMAC.MasterCompanyId
			    Where ESOBI.SOBillingInvoicingId=@InvoicingId AND ISNULL(ESO.IsVendor , 0) = 0

			END
			ELSE 
			BEGIN 

		      SELECT WOBI.BillingInvoicingId [InvoiceId],WOBI.InvoiceNo [InvoiceNo],
				WOBI.InvoiceStatus [InvoiceStatus],
				--WOBI.InvoiceDate [InvoiceDate],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				  CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			    ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				WO.WorkOrderNum [OrderNumber],
				C.Name [CustomerName],CT.CustomerTypeName [CustomerType],
				WOBI.GrandTotal [InvoiceAmt],
				IsWorkOrder=1,
				WOBI.ReferenceId AS [ReferenceId]
			   ,WOBI.ManagementStructureId as ManagementStructureId
			   ,(CON.FirstName +' '+ CON.LastName +' - '+ CON.WorkPhone) as ContactInfo
			   ,WO.CustomerContactId as  CustomerContactId
			   ,RMAC.RMAReasonId
			   ,RMAC.RMAReason
			   ,RMAC.RMAStatusId
			   ,RMAC.RMAStatus
			   ,RMAC.ValidDays
			   ,WOBI.MasterCompanyId
			   ,C.CustomerId
			   ,c.CustomerCode
			   ,'0' as AddressCount
			   ,'0' as PartCount
			   ,@WOInvoiceTypeId AS 'InvoiceTypeId'
				FROM dbo.BillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN [dbo].WorkOrder WO WITH (NOLOCK) ON WOBI.ReferenceId = WO.WorkOrderId
				LEFT JOIN [dbo].Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
				LEFT JOIN [dbo].CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN [dbo].CustomerContact CUN WITH (NOLOCK) ON CUN.CustomerContactId=WO.CustomerContactId
				LEFT JOIN [dbo].Contact CON WITH (NOLOCK) ON CON.ContactId=CUN.ContactId
				LEFT JOIN [dbo].RMACreditMemoSettings RMAC WITH (NOLOCK) ON wo.MasterCompanyId = RMAC.MasterCompanyId
			    Where WOBI.BillingInvoicingId=@InvoicingId AND WOBI.IsVersionIncrease=0 AND WOBI.ModuleId = @workOrderModuleId
			
			END
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetCustomerInvoicedatabyInvoiceId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@InvoicingId, '') + '''
													   @Parameter18 = ' + ISNULL(CAST(@isWorkOrder AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH


	
END