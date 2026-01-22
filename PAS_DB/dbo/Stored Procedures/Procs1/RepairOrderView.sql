/************************************************************************************           
 ** File:   [RepairOrderView]           
 ** Author: 
 ** Description: This stored procedure is used to get RepairOrder header data.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date					Author				Change Description            
 ** --    --------			-----------				--------------------------------          
	 1    04-07-2025			Amit Ghediya			Created
	 2    05-28-2025			Devendra Shekh			Added IsEnforcePickTicket to select

	 EXEC [dbo].[RepairOrderView] 2542
****************************************************************************************/
CREATE    PROCEDURE [dbo].[RepairOrderView]
	 @RepairOrderId BIGINT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
			
			DECLARE @ROModuleId INT,
					@ROHeaderModuleId INT;

			--Get ModuleId
			SELECT @ROModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'RepairOrder';
			SELECT @ROHeaderModuleId = [ManagementStructureModuleId] FROM [DBO].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ROHeader';


			SELECT 
				RO.RepairOrderId,
				RO.MasterCompanyId,
				RO.RepairOrderNumber,
				RO.VendorName,
				RO.ChargesBilingMethodId,
				RO.FreightBilingMethodId,
				RO.Requisitioner,
				RO.RequisitionerId,
				RO.VendorContactId,
				RO.OpenDate,
				RO.VendorCode,
				RO.ApprovedBy AS Approver,
				RO.ClosedDate,
				RO.VendorContactPhone AS WorkPhone,
				RO.VendorContactEmail,
				RO.VendorContact AS ContactName,
				RO.Status,
				RO.StatusId,
				RO.Priority AS Description,
				RO.CreditLimit,
				RO.Terms AS CreditTerm,
				RO.Resale,
				RO.RoMemo,
				RO.Notes,
				RO.DeferredReceiver,
				ISNULL(POSADD.UserTypeName, '') AS ShipToUserType,
				ISNULL(POSADD.UserName, '') AS ShipToUser,
				ISNULL(POSADD.SiteName, '') AS ShipToSiteName,
				ISNULL(POSADD.ContactName, '') AS ShipToContact,
				ISNULL(POSADD.ContactPhoneNo, '') AS ShipToContactPhone,
				ISNULL(ROCON.Email, '') AS ShipToContactEmail,
				ISNULL(POSADD.ContactId, 0) AS ShipToContactId,
				ISNULL(POSADD.Memo, '') AS ShipToMemo,
				ISNULL(POSADD.AddressID, 0) AS ShipToAddressId,
				ISNULL(POSADD.Line1, '') AS ShipToAddress1,
				ISNULL(POSADD.Line2, '') AS ShipToAddress2,
				ISNULL(POSADD.City, '') AS ShipToCity,
				ISNULL(POSADD.Country, '') AS ShipToCountry,
				ISNULL(POSADD.StateOrProvince, '') AS ShipToState,
				ISNULL(POSADD.PostalCode, '') AS ShipToPostalCode,
				ISNULL(ROSV.ShipViaId, 0) AS ShipViaId,
				ISNULL(ROSV.ShipVia, '') AS ShipVia,
				ISNULL(ROSV.ShippingCost, 0) AS ShippingCost,
				ISNULL(ROSV.HandlingCost, 0) AS HandlingCost,
				ISNULL(ROSV.ShippingAccountNo, '') AS ShippingAccountNo,
				ISNULL(POBADD.UserTypeName, '') AS BillToUserType,
				ISNULL(POBADD.UserName, '') AS BillToUser,
				ISNULL(POBADD.UserId, 0) AS BillToUserId,
				ISNULL(POBADD.SiteId, 0) AS BillToSiteId,
				ISNULL(POBADD.SiteName, '') AS BillToSiteName,
				ISNULL(POBADD.ContactId, 0) AS BillToContactId,
				ISNULL(POBADD.ContactName, '') AS BillToContactName,
				ISNULL(POBADD.ContactPhoneNo, '') AS BillToContactPhone,
				ISNULL(ROBCON.Email, '') AS BillToContactEmail,
				ISNULL(POBADD.AddressID, 0) AS BillToAddressId,
				ISNULL(POBADD.Line1, '') AS BillToAddress1,
				ISNULL(POBADD.Line2, '') AS BillToAddress2,
				ISNULL(POBADD.City, '') AS BillToCity,
				ISNULL(POBADD.StateOrProvince, '') AS BillToState,
				ISNULL(POBADD.Country, '') AS BillToCountry,
				ISNULL(POBADD.PostalCode, '') AS BillToPostalCode,
				ISNULL(POBADD.Memo, '') AS BillToMemo,
				RO.VendorId,
				RO.ManagementStructureId,
				RO.NeedByDate,
				RO.Priority,
				RO.ApprovedDate,
				RO.Level1,
				RO.Level2,
				RO.Level3,
				RO.Level4,
				ISNULL(VW.WarningMessage, '') AS WarningMessage,
				RO.IsEnforce,
				RO.UpdatedDate,
				ISNULL(MSD.LastMSLevel, '') AS LastMSLevel,
				ISNULL(MSD.AllMSlevels, '') AS AllMSlevels,
				ISNULL(RO.TotalCharges, 0) AS TotalCharges,
				ISNULL(RO.TotalFreight, 0) AS TotalFreight,
				ISNULL(RO.IsLotAssigned, 0) AS IsLotAssigned,
				ISNULL(RO.LotId, 0) AS LotId,
				ISNULL(ROSV.ShippingTerms, '') AS ShippingTerms,
				ISNULL(FCU.Code, '') AS FunctionalCurrency,
				ISNULL(RCU.Code, '') AS ReportCurrency,
				ISNULL(RO.ForeignExchangeRate, 0) AS ForeignExchangeRate,
				ISNULL(RO.IsEnforcePickTicket, 0) AS IsEnforcePickTicket
			FROM [DBO].[RepairOrder] RO WITH(NOLOCK)
			LEFT JOIN [DBO].[AllAddress] POSADD WITH(NOLOCK) ON RO.RepairOrderId = POSADD.ReffranceId AND POSADD.IsShippingAdd = 1 AND POSADD.ModuleId = @ROModuleId
			LEFT JOIN [DBO].[Contact] ROCON WITH(NOLOCK) ON POSADD.ContactId = ROCON.ContactId
			LEFT JOIN [DBO].[AllAddress] POBADD WITH(NOLOCK) ON RO.RepairOrderId = POBADD.ReffranceId AND POBADD.IsShippingAdd = 0 AND POBADD.ModuleId = @ROModuleId
			LEFT JOIN [DBO].[Contact] ROBCON WITH(NOLOCK) ON POBADD.ContactId = ROBCON.ContactId
			LEFT JOIN [DBO].[AllShipVia] ROSV WITH(NOLOCK) ON RO.RepairOrderId = ROSV.ReferenceId AND ROSV.ModuleId = @ROModuleId
			LEFT JOIN [DBO].[VendorWarning] VW WITH(NOLOCK) ON RO.VendorId = VW.VendorId AND VW.Warning = 1
			LEFT JOIN [DBO].[RepairOrderManagementStructureDetails] MSD ON RO.RepairOrderId = MSD.ReferenceID AND MSD.ModuleID = @ROHeaderModuleId
			LEFT JOIN [DBO].[Currency] FCU WITH(NOLOCK) ON RO.FunctionalCurrencyId = FCU.CurrencyId AND FCU.IsActive = 1 AND FCU.IsDeleted = 0
			LEFT JOIN [DBO].[Currency] RCU WITH(NOLOCK) ON RO.ReportCurrencyId = RCU.CurrencyId AND RCU.IsActive = 1 AND RCU.IsDeleted = 0
			WHERE RO.RepairOrderId = @RepairOrderId;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RepairOrderView' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END