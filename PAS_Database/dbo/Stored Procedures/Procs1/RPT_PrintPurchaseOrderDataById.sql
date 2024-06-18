/*************************************************************           
 ** File:  [RPT_PrintPurchaseOrderDataById]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Get Print PurchaseOrder Data By PurchaseOrderId
 ** Purpose:         
 ** Date:   02/03/2023      
          
 ** PARAMETERS: @PurchaseOrderId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/03/2023  Amit Ghediya    Created
     
-- EXEC RPT_PrintPurchaseOrderDataById 629
************************************************************************/
CREATE   PROCEDURE [dbo].[RPT_PrintPurchaseOrderDataById]
@PurchaseOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

		DECLARE @ModuleID BIGINT,
		        @OtherModuleID BIGINT, 
				@VendorWarningListName VARCHAR(200),
				@IsTrue INT = 1,
				@IsFalse INT = 0,
				@VendorId BIGINT,
				@PurchaseOrderPartRecordId BIGINT,@POPart BIGINT,@NumofRecords BIGINT;
		
		SELECT @ModuleID = ModuleId FROM Module WITH (NOLOCK) WHERE ModuleName = 'PurchaseOrder';
		SELECT @OtherModuleID = ModuleId FROM Module WITH (NOLOCK) WHERE ModuleName = 'Others';
		SELECT @POPart = ModuleId FROM Module WITH (NOLOCK) WHERE ModuleName = 'Revision';
		SELECT
		 @NumofRecords = COUNT(PO.[PurchaseOrderId])
		FROM [DBO].[PurchaseOrder] PO WITH (NOLOCK)
		LEFT JOIN [DBO].[AllAddress] AD WITH (NOLOCK) ON PO.PurchaseOrderId = AD.ReffranceId AND Ad.IsShippingAdd = @IsTrue AND Ad.ModuleId = @ModuleID
		LEFT JOIN [DBO].[AllAddress] ADB WITH (NOLOCK) ON PO.PurchaseOrderId = AdB.ReffranceId AND ADB.IsShippingAdd = @IsFalse AND ADB.ModuleId = @ModuleID
		LEFT JOIN [DBO].[AllShipVia] ASV WITH (NOLOCK) ON PO.PurchaseOrderId = ASV.ReferenceId AND ASV.ModuleId = @ModuleID
		LEFT JOIN [DBO].[VendorWarning] VW WITH (NOLOCK) ON PO.VendorId = VW.VendorId AND VW.Warning = @IsTrue
		LEFT JOIN [DBO].[VendorWarningList] VWL WITH (NOLOCK) ON VW.VendorWarningListId = VWL.VendorWarningListId AND VWL.Name = @VendorWarningListName
		LEFT JOIN [DBO].[PurchaseOrderManagementStructureDetails] PMSD WITH (NOLOCK) ON PO.PurchaseOrderId = PMSD.ReferenceID AND PMSD.ModuleID = @OtherModuleID
		WHERE PO.[PurchaseOrderId] = @PurchaseOrderId;
		
		SET @VendorWarningListName = 'Create Purchase Order';

		SELECT PO.[PurchaseOrderId] AS 'PurchaseOrderId',
			   PO.[MasterCompanyId] AS 'MasterCompanyId',
			   PO.[PurchaseOrderNumber] AS 'PurchaseOrderNumber',
			   PO.[ChargesBilingMethodId] AS 'ChargesBilingMethodId',
			   ISNULL(PO.[TotalCharges],0) AS 'TotalCharges',
			   ISNULL(PO.[TotalFreight],0) AS 'TotalFreight',
			   --PO.[VendorName] AS 'VendorName',
			   CASE
			   WHEN PO.[VendorName] !='' 
			   THEN 
					CASE WHEN LEN(ISNULL(PO.[VendorName],'')) < 38
						THEN ISNULL(PO.[VendorName],'')
					ELSE
						LEFT(ISNULL(PO.[VendorName],''),38) + '....'
					END
			   ELSE 
					''
			   END AS 'VendorName',
			   PO.[Requisitioner] AS 'Requisitioner',
			   PO.[RequestedBy] AS 'RequestedBy',
			   PO.[VendorContactId] AS 'VendorContactId',
			   PO.[OpenDate] AS 'OpenDate',
			   PO.[VendorCode] AS 'VendorCode',
			   PO.[Priority] AS 'Priority',
			   PO.[ApprovedBy] AS 'Approver',
			   PO.[ClosedDate] AS 'ClosedDate',
			   PO.[VendorContactPhone] AS 'WorkPhone',
			   PO.[VendorContact] AS 'VendorContact',
			   PO.[Status] AS 'Status',
			   PO.[Priority] AS 'Description',
			   PO.[CreditLimit] AS' CreditLimit',
			   PO.[Terms] AS 'CreditTerm',
			   PO.[Resale] AS 'Resale',
			   PO.[Notes] AS 'Notes',
			   PO.[POMemo] AS 'POMemo',
			   PO.[DeferredReceiver] AS 'DeferredReceiver',
			   PO.[VendorId] AS VendorId,
			  -- @VendorId = PO.[VendorId],
			   PO.[ManagementStructureId] AS 'ManagementStructureId',
			   PO.[NeedByDate] AS 'NeedByDate',
			   PO.[DateApproved] AS 'DateApproved',
			   PO.[IsEnforce] AS 'IsEnforce',
			   PO.[UpdatedDate] AS 'UpdatedDate',
			   ISNULL(AD.[UserTypeName],'') AS 'ShipToUserType',
			   ISNULL(Ad.[UserName],'') AS 'ShipToUser',
			   ISNULL(Ad.[SiteName],'') AS 'ShipToSiteName',
			   ISNULL(Ad.[ContactName],'') AS 'ShipToContact',
			   ISNULL(Ad.[ContactPhoneNo],'') AS 'ShipToContactPhone',
			   ISNULL(SC.[Email],'') AS 'ShipToContactEmail',
			   ISNULL(Ad.[ContactId],0) AS 'ShipToContactId',
			   ISNULL(Ad.[Memo],'') AS 'ShipToMemo',
			   ISNULL(Ad.[AddressID],0) AS 'ShipToAddressId',
			   ISNULL(Ad.[Line1],'') AS 'ShipToAddress1',
			   ISNULL(Ad.[Line2],'') AS 'ShipToAddress2',
			   CASE
			   WHEN Ad.[Line1] !='' OR Ad.[Line2] !='' 
			   THEN 
					ISNULL(Ad.[Line1],'') +' '+ ISNULL(Ad.[Line2],'')
					--CASE WHEN LEN(ISNULL(Ad.[Line1],'') +' '+ ISNULL(Ad.[Line2],'')) < 25
					--	THEN ISNULL(Ad.[Line1],'') +' '+ ISNULL(Ad.[Line2],'')
					--ELSE
					--	LEFT(ISNULL(Ad.[Line1],'') +' '+ ISNULL(Ad.[Line2],''),25) + '....'
					--END					
			   ELSE
					''
			   END  AS 'ShipAddCommon',

			   ISNULL(Ad.[City],'') AS 'ShipToCity',
			   ISNULL(Ad.[StateOrProvince],'') AS 'ShipToState',
			   ISNULL(Ad.[PostalCode],'') AS 'ShipToPostalCode',
			   CASE
			   WHEN Ad.[City] !='' OR Ad.[StateOrProvince] !='' OR Ad.[PostalCode] != '' 
			   THEN 
					ISNULL(Ad.[City],'') +' '+ ISNULL(Ad.[StateOrProvince],'') +', ' + ISNULL(Ad.[PostalCode],'')
					--CASE WHEN LEN(ISNULL(Ad.[City],'') +' '+ ISNULL(Ad.[StateOrProvince],'') +', ' + ISNULL(Ad.[PostalCode],'')) < 25
					--	THEN ISNULL(Ad.[City],'') +' '+ ISNULL(Ad.[StateOrProvince],'') +', ' + ISNULL(Ad.[PostalCode],'')
					--ELSE
					--	LEFT(ISNULL(Ad.[City],'') +' '+ ISNULL(Ad.[StateOrProvince],'') +', ' + ISNULL(Ad.[PostalCode],''),25) + '....'
					--END
			   ELSE
					''
			   END  AS 'ShipCommon',
			   --LEFT(ISNULL(Ad.[City],'') +' '+ ISNULL(Ad.[StateOrProvince],'') +', ' + ISNULL(Ad.[PostalCode],''),20) + '....' AS 'ShipCommon',

			   ISNULL(Ad.[Country],'') AS 'ShipToCountry',		   
			   ISNULL(ASV.[ShipViaId],0) AS 'ShipViaId',
			   ISNULL(ASV.[ShipVia],'') AS 'ShipVia',
			   ISNULL(ASV.[ShippingCost],0) AS 'ShippingCost',
			   ISNULL(ASV.[HandlingCost],0) AS 'HandlingCost',
			   --ISNULL(ASV.[ShippingAccountNo],'') AS 'ShippingAccountNo',
			   CASE
			   WHEN ASV.[ShippingAccountNo] !='' 
			   THEN 
					CASE WHEN LEN(ISNULL(ASV.[ShippingAccountNo],'')) < 38
						THEN ISNULL(ASV.[ShippingAccountNo],'')
					ELSE
						LEFT(ISNULL(ASV.[ShippingAccountNo],''),38) + '....'
					END
			   ELSE 
					''
			   END AS 'ShippingAccountNo',
			   ISNULL(ADB.[UserTypeName],'') AS 'BillToUserType',	   
			   ISNULL(ADB.[UserName],'') AS 'BillToUser',
			   ISNULL(ADB.[UserId],0) AS 'BillToUserId',
			   ISNULL(ADB.[SiteId],0) AS 'BillToSiteId',
			   ISNULL(ADB.[SiteName],'') AS 'BillToSiteName',
			   ISNULL(ADB.[ContactId],0) AS 'BillToContactId',
			   ISNULL(ADB.[ContactName],'') AS 'BillToContactName',
			   ISNULL(ADB.[ContactPhoneNo],'') AS 'BillToContactPhone',
			   ISNULL(BC.[Email],'') AS 'BillToContactEmail',				   
			   ISNULL(ADB.[AddressID],0) AS 'BillToAddressId',
			   ISNULL(ADB.[Line1],'') AS 'BillToAddress1',
			   ISNULL(ADB.[Line2],'') AS 'BillToAddress2',

			   CASE
			   WHEN ADB.[Line1] !='' OR ADB.[Line2] !='' 
			   THEN
					ISNULL(ADB.[Line1],'') +' '+ ISNULL(ADB.[Line2],'')
					--CASE WHEN LEN(ISNULL(ADB.[Line1],'') +' '+ ISNULL(ADB.[Line2],'')) < 25
					--	THEN ISNULL(ADB.[Line1],'') +' '+ ISNULL(ADB.[Line2],'')
					--ELSE
					--	LEFT(ISNULL(ADB.[Line1],'') +' '+ ISNULL(ADB.[Line2],''),25) + '....'
					--END						
			   ELSE
					''
			   END  AS 'BillAddCommon',

			   ISNULL(ADB.[City],'') AS 'BillToCity',
			   ISNULL(ADB.[StateOrProvince],'') AS 'BillToState',
			   ISNULL(ADB.[PostalCode],'') AS 'BillToPostalCode',

			   CASE
			   WHEN ADB.[City] !='' OR ADB.[StateOrProvince] !='' OR ADB.[PostalCode] != '' 
			   THEN
					ISNULL(ADB.[City],'') +' '+ ISNULL(ADB.[StateOrProvince],'') +', ' + ISNULL(ADB.[PostalCode],'')
					--CASE WHEN LEN(ISNULL(ADB.[City],'') +' '+ ISNULL(ADB.[StateOrProvince],'') +', ' + ISNULL(ADB.[PostalCode],'')) < 25
					--	THEN ISNULL(ADB.[City],'') +' '+ ISNULL(ADB.[StateOrProvince],'') +', ' + ISNULL(ADB.[PostalCode],'')
					--ELSE
					--	LEFT(ISNULL(ADB.[City],'') +' '+ ISNULL(ADB.[StateOrProvince],'') +', ' + ISNULL(ADB.[PostalCode],''),25) + '....'
					--END					
			   ELSE
					''
			   END  AS 'BillCommon',

			   ISNULL(ADB.[Country],'') AS 'BillToCountry',
			
			   ISNULL(ADB.[Memo],'') AS 'BillToMemo',
			   --VW.[WarningMessage] AS 'WarningMessage',
			   '' AS 'WarningMessage',
			   ISNULL(PMSD.[LastMSLevel],'') AS 'LastMSLevel',
			   ISNULL(PMSD.[AllMSlevels],'') AS 'AllMSlevels',
			   @NumofRecords AS 'NumOfRecords'
		FROM [DBO].[PurchaseOrder] PO WITH (NOLOCK)
		LEFT JOIN [DBO].[AllAddress] AD WITH (NOLOCK) ON PO.PurchaseOrderId = AD.ReffranceId AND Ad.IsShippingAdd = @IsTrue AND Ad.ModuleId = @ModuleID
		LEFT JOIN [DBO].[Contact] SC WITH (NOLOCK) ON SC.ContactId = AD.ContactId
		LEFT JOIN [DBO].[AllAddress] ADB WITH (NOLOCK) ON PO.PurchaseOrderId = AdB.ReffranceId AND ADB.IsShippingAdd = @IsFalse AND ADB.ModuleId = @ModuleID
		LEFT JOIN [DBO].[Contact] BC WITH (NOLOCK) ON BC.ContactId = ADB.ContactId
		LEFT JOIN [DBO].[AllShipVia] ASV WITH (NOLOCK) ON PO.PurchaseOrderId = ASV.ReferenceId AND ASV.ModuleId = @ModuleID
		--LEFT JOIN [DBO].[VendorWarning] VW WITH (NOLOCK) ON PO.VendorId = VW.VendorId AND VW.Warning = @IsTrue
		--LEFT JOIN [DBO].[VendorWarningList] VWL WITH (NOLOCK) ON VW.VendorWarningListId = VWL.VendorWarningListId AND VWL.Name = @VendorWarningListName
		LEFT JOIN [DBO].[PurchaseOrderManagementStructureDetails] PMSD WITH (NOLOCK) ON PO.PurchaseOrderId = PMSD.ReferenceID AND PMSD.ModuleID = @OtherModuleID
		WHERE PO.[PurchaseOrderId] = @PurchaseOrderId;
		

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'RPT_PrintPurchaseOrderDataById' 
        ,@ProcedureParameters VARCHAR(3000) = '@PurchaseOrderId = ''' + CAST(ISNULL(@PurchaseOrderId, '') AS varchar(100))			   
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