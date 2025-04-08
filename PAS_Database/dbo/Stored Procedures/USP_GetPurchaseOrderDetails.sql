/*************************************************************           
 ** File:   [USP_GetPurchaseOrderDetails]           
 ** Author:   Bhargav Saliya
 ** Description: Get Data for Purchase order view Data    
 ** Purpose:         
 ** Date:   02-April-2025        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author			Change Description            
 ** --   --------			-------			--------------------------------          
    1    02-April-2025   Bhargav Saliya		Created
exec [dbo].[USP_GetPurchaseOrderDetails] @PurchaseOrderId = 6708
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetPurchaseOrderDetails]
    @PurchaseOrderId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  

	DECLARE @MsModuleId BIGINT = (SELECT ManagementStructureModuleId FROM [dbo].ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'POHeader');
	DECLARE @ModuleId BIGINT = (SELECT ModuleId FROM [dbo].Module WITH(NOLOCK) where ModuleName = 'PurchaseOrder' and CodePrefix = 'PO');
	DECLARE @CreatePO VARCHAR(30) = 'CREATE PURCHASE ORDER'

	BEGIN TRY
	BEGIN
		SELECT 
			po.PurchaseOrderId,
			po.MasterCompanyId,
			po.PurchaseOrderNumber,
			po.ChargesBilingMethodId,
			ISNULL(po.TotalCharges, 0) AS TotalCharges,
			ISNULL(po.TotalFreight, 0) AS TotalFreight,
			po.VendorName,
			po.Requisitioner,
			po.RequestedBy,
			po.VendorContactId,
			po.OpenDate,
			po.VendorCode,
			po.Priority,
			po.ApprovedBy AS Approver,
			po.ClosedDate,
			po.VendorContactPhone AS WorkPhone,
			po.VendorContactEmail,
			po.VendorContact,
			po.Status,
			po.Priority AS Description,
			po.CreditLimit,
			po.Terms AS CreditTerm,
			po.Resale,
			po.Notes,
			po.POMemo,
			po.DeferredReceiver,
			ISNULL(posadd.UserTypeName,'') AS ShipToUserType,
			ISNULL(posadd.UserName,'') AS ShipToUser,
			ISNULL(posadd.SiteName,'') AS ShipToSiteName,
			ISNULL(posadd.ContactName,'') AS ShipToContact,
			ISNULL(posadd.ContactPhoneNo,'') AS ShipToContactPhone,
			ISNULL(posadd.ContactId, 0) AS ShipToContactId,
			ISNULL(posadd.Memo,'') AS ShipToMemo,
			ISNULL(posadd.AddressID, 0) AS ShipToAddressId,
			ISNULL(posadd.Line1,'') AS ShipToAddress1,
			ISNULL(posadd.Line2,'') AS ShipToAddress2,
			ISNULL(posadd.City,'') AS ShipToCity,
			ISNULL(posadd.Country,'') AS ShipToCountry,
			ISNULL(posadd.StateOrProvince,'') AS ShipToState,
			ISNULL(posadd.PostalCode,'') AS ShipToPostalCode,
			ISNULL(posv.ShipViaId,0) as ShipViaId,
			ISNULL(posv.ShipVia,'') as ShipVia,
			ISNULL(posv.ShippingCost,0) as ShippingCost,
			ISNULL(posv.HandlingCost,0) as HandlingCost,
			ISNULL(posv.ShippingAccountNo,'') as ShippingAccountNo,
			ISNULL(pobadd.UserTypeName,'') AS BillToUserType,
			ISNULL(pobadd.UserName,'') AS BillToUser,
			ISNULL(pobadd.UserId,0) AS BillToUserId,
			ISNULL(pobadd.SiteId,0) AS BillToSiteId,
			ISNULL(pobadd.SiteName,'') AS BillToSiteName,
			ISNULL(pobadd.ContactId,0) AS BillToContactId,
			ISNULL(pobadd.ContactName,'') AS BillToContactName,
			ISNULL(pobadd.ContactPhoneNo,'') AS BillToContactPhone,
			ISNULL(pobadd.AddressID,0) AS BillToAddressId,
			ISNULL(pobadd.Line1,'') AS BillToAddress1,
			ISNULL(pobadd.Line2,'') AS BillToAddress2,
			ISNULL(pobadd.City,'') AS BillToCity,
			ISNULL(pobadd.StateOrProvince,'') AS BillToState,
			ISNULL(pobadd.Country,'') AS BillToCountry,
			ISNULL(pobadd.PostalCode,'') AS BillToPostalCode,
			ISNULL(pobadd.Memo,'') AS BillToMemo,
			po.VendorId,
			po.ManagementStructureId,
			po.NeedByDate,
			po.DateApproved,
			vW.WarningMessage,
			'' AS Barcode,
			po.IsEnforce,
			po.UpdatedDate,
			ISNULL(msd.LastMSLevel,'') as LastMSLevel,
			ISNULL(msd.AllMSlevels,'') as AllMSlevels,
			ISNULL(po.IsLotAssigned, 0) AS IsLotAssigned,
			ISNULL(po.LotId, 0) AS LotId,
			ISNULL(lt.LotNumber, '') AS LotNumber,
			ISNULL(posv.ShippingTerms, '') AS ShippingTerms,
			ISNULL(fcu.Code, '') AS FunctionalCurrency,
			ISNULL(rcu.Code, '') AS ReportCurrency,
			CASE WHEN po.ForeignExchangeRate > 0 THEN po.ForeignExchangeRate ELSE 0 END AS ForeignExchangeRate
		FROM PurchaseOrder po WITH(NOLOCK)
		LEFT JOIN [dbo].AllAddress posadd WITH(NOLOCK) ON po.PurchaseOrderId = posadd.ReffranceId AND posadd.IsShippingAdd = 1 AND posadd.ModuleId = @ModuleId
		LEFT JOIN [dbo].AllAddress pobadd WITH(NOLOCK) ON po.PurchaseOrderId = pobadd.ReffranceId AND pobadd.IsShippingAdd = 0 AND pobadd.ModuleId = @ModuleId
		LEFT JOIN [dbo].AllShipVia posv WITH(NOLOCK) ON po.PurchaseOrderId = posv.ReferenceId AND posv.ModuleId = @ModuleId
		LEFT JOIN [dbo].VendorWarning vW WITH(NOLOCK) ON po.VendorId = vW.VendorId AND vW.Warning = 1
		LEFT JOIN [dbo].Lot lt WITH(NOLOCK) ON po.LotId = lt.LotId
		LEFT JOIN [dbo].VendorWarningList vWL WITH(NOLOCK) ON vW.VendorWarningListId = vWL.VendorWarningListId AND UPPER(vWL.Name) = @CreatePO
		LEFT JOIN [dbo].PurchaseOrderManagementStructureDetails msd WITH(NOLOCK) ON po.PurchaseOrderId = msd.ReferenceID AND msd.ModuleID = @MsModuleId
		LEFT JOIN [dbo].Currency fcu WITH(NOLOCK) ON po.FunctionalCurrencyId = fcu.CurrencyId AND fcu.IsActive = 1 AND fcu.IsDeleted = 0
		LEFT JOIN [dbo].Currency rcu WITH(NOLOCK) ON po.ReportCurrencyId = rcu.CurrencyId AND rcu.IsActive = 1 AND rcu.IsDeleted = 0
		WHERE po.PurchaseOrderId = @PurchaseOrderId;
	END
	END TRY
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetPurchaseOrderDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END