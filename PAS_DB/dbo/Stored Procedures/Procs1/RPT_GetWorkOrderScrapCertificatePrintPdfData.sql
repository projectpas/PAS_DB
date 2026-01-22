
/***************************************************************************************************
** Author:  <Moin Bloch>  
** Create date: 16/01/2026
** Description: <Get Work order Scrap Certificate Form Data>  
 
EXEC [RPT_GetWorkOrderScrapCertificatePrintPdfData]
***************************************************************************************************
** Change History
***************************************************************************************************  
** PR   Date        Author				Change Description  
** --   --------    -------				--------------------------------
** 1    16/01/2026   Moin Bloch         CREATED

	EXEC RPT_GetWorkOrderScrapCertificatePrintPdfData 4103,3620
***************************************************************************************************/
CREATE     PROCEDURE [dbo].[RPT_GetWorkOrderScrapCertificatePrintPdfData]              
@WorkorderId BIGINT,              
@workOrderPartNoId BIGINT              
AS              
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON;                           
  BEGIN TRY     
		DECLARE @MergedBillToAddress AS VARCHAR(max)
		DECLARE @BAddress1 NVARCHAR(255),@BAddress2 NVARCHAR(255),@BCity NVARCHAR(100),@BStateOrProvince NVARCHAR(100),@BPostalCode NVARCHAR(20),@billAttention NVARCHAR(200)
		DECLARE @BCountry NVARCHAR(100),@BPhoneNumber NVARCHAR(50),@BPhoneExt NVARCHAR(10),@BEmail NVARCHAR(255);

		SELECT @BAddress1 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress1) else UPPER(billToAddress.Line1) END,              
			   @BAddress2 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress2) else UPPER(billToAddress.Line2) END,
		   	   @BCity = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCity) else UPPER(billToAddress.City) END,              
			   @BStateOrProvince = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToState) else UPPER(billToAddress.StateOrProvince) END,              
			   @BPostalCode = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToZip) else UPPER(billToAddress.PostalCode) END,					  
			   @BCountry = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCountryName) else UPPER(billToCountry.countries_name) END,              
			   @billAttention = CASE WHEN shippingInfo.WorkOrderId > 0  THEN 'ATTN: ' + UPPER(billToSiteatt.Attention) else 'ATTN: ' + UPPER(billToSite.Attention) END,			   
			   @BPhoneNumber = UPPER(ISNULL(cont.WorkPhone, '')),
			   @BEmail = UPPER(ISNULL(cont.Email, ''))
		  FROM [dbo].[WorkOrder] WO WITH (NOLOCK)
		 INNER JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WO.WorkOrderId AND WOPN.ID = @workOrderPartNoId				
		  LEFT JOIN [dbo].[WorkOrderShipping] shippingInfo WITH(NOLOCK) on shippingInfo.WorkOrderId = wo.WorkOrderId and shippingInfo.WorkOrderPartNoId=WOPN.ID  
		  LEFT JOIN [dbo].[CustomerBillingAddress]  billToSiteatt WITH(NOLOCK) on shippingInfo.SoldToSiteId = billToSiteatt.CustomerBillingAddressId        
		  LEFT JOIN [dbo].[Customer] billToCustomer WITH(NOLOCK) ON wo.CustomerId = billToCustomer.CustomerId              
		  LEFT JOIN [dbo].[CustomerBillingAddress]  billToSite WITH(NOLOCK) ON wo.CustomerId = billToSite.CustomerId and billToSite.IsPrimary=1              
		  LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId              
		  LEFT JOIN [dbo].[Countries] billToCountry WITH(NOLOCK) ON billToCountry.countries_id = billToAddress.CountryId   
		  LEFT JOIN [dbo].[CustomerContact] custcont WITH(NOLOCK) ON WO.CustomerContactId = custcont.CustomerContactId AND custcont.IsDefaultContact = 1
		  LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON custcont.ContactId = cont.ContactId
		 WHERE WOPN.ID=@workOrderPartNoId AND WO.WorkOrderId=@workOrderId
  
		EXEC [dbo].[SP_ValidatePDFAddress] 
                @Address1 = @BAddress1,
                @Address2 = @BAddress2,
                @Address3 = NULL,
                @City = @BCity,
                @StateOrProvince = @BStateOrProvince,
                @PostalCode = @BPostalCode,
                @Country = @BCountry,
                @PhoneNumber = @BPhoneNumber,
                @PhoneExt = @BPhoneExt,
                @Email = @BEmail,
                @AddressOutput = @MergedBillToAddress OUTPUT;
			
		  SELECT TOP 1 UPPER(WO.WorkOrderNum) AS WorkOrderNumber
				,UPPER(WO.CustomerName) AS CustomerName
				,UPPER(imt.PartNumber)  AS 'PartNumber'
				,UPPER(WOPN.RevisedPartNumber) AS RevisedPartNumber							   
				,CASE WHEN LEN(UPPER(imt.PartDescription)) > 20 THEN LEFT(UPPER(imt.PartDescription), 20) + '...' ELSE  UPPER(imt.PartDescription) END AS PartDescription
				,UPPER(WOPN.CustomerReference) AS CustomerReference
				,UPPER(WOPN.CurrentSerialNumber) AS SerialNumber
				,UPPER(WOPN.RevisedSerialNumber) AS RevisedSerialNumber 
				,UPPER(SR.Reason) AS ScrapReason				
				,FORMAT(SC.ScrapCertificateDate	, 'MM/dd/yyyy') AS ScrapCertificateDate
				,'THOROUGH MUTILATION ' AS ScrapMethod
				,@MergedBillToAddress MergedBillToAddress
				,@billAttention billAttention
		   FROM [dbo].[WorkOrder] WO WITH (NOLOCK)
				INNER JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WO.WorkOrderId AND WOPN.ID = @workOrderPartNoId
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOPN.ItemMasterId=IM.ItemMasterId
				 LEFT JOIN [dbo].[ScrapCertificate] SC WITH (NOLOCK) ON SC.WorkOrderId=WO.WorkOrderId AND WOPN.ID=SC.workOrderPartNoId
				 LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = WOPN.ItemMasterId
				 LEFT JOIN [dbo].[ScrapReason] SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId 
		   WHERE WOPN.[ID]=@workOrderPartNoId AND WO.[WorkOrderId]=@workOrderId       
             
  END TRY                  
  BEGIN CATCH                    
   IF @@trancount > 0              
    PRINT 'ROLLBACK'              
    --ROLLBACK TRAN;              
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()              
             
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetWorkOrderScrapCertificatePrintPdfData'              
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''              
                @Parameter2 = ' + ISNULL(@workOrderPartNoId ,'') +''              
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