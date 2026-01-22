/*************************************************************               
 ** File:   [USP_Refresh_Vendor_CreditLimit_Terms]               
 ** Author: Devendra Shekh
 ** Description:  This Store Procedure is used to Refresh Vendor CreditLimit and Terms
 ** Date:   17 April 2025      
 **********************************************************               
 ** Refresh CreditLimit and Terms               
 **********************************************************               
 ** PR   Date				Author				Change Description                
 ** --   --------			-------				--------------------------------              
    1    17-April-2025		Devendra Shekh		Created
********************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_Refresh_Vendor_CreditLimit_Terms]
	@VendorId BIGINT = NULL,
	@ReferenceId BIGINT = NULL,
	@ModuleId INT = NULL,
	@MasterCompanyId INT = NULL,
	@IsGetVendorCredirTems BIT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @CeraditLimit DECIMAL(18,2),
                @CreditTermsId BIGINT,
				@CreaditTerms VARCHAR(50),
			    @AccountType VARCHAR(50),
				@AccountTypeId BIGINT,
				@VendorName VARCHAR(100);
		
		DECLARE @POModuleId INT, @ROModuleId INT, @RFQPOModuleId INT, @RFQROModuleId INT;

		SELECT @POModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'PurchaseOrder';
		SELECT @ROModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'RepairOrder';
		SELECT @RFQPOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPurchaseOrder';
		SELECT @RFQROModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQRepairOrder';

		IF(ISNULL(@IsGetVendorCredirTems, 0) = 1)
		BEGIN
			;WITH Result(CreditLimit, CreditTermId, AccountTypeName, AccountTypeId, CreditTermName, VendorName) AS(
			SELECT  V.CreditLimit AS CreditLimit,
					V.CreditTermsId AS CreditTermId,
					VT.[Description] AS AccountTypeName,
					V.VendorTypeId AS AccountTypeId ,
					CR.[Name] AS CreditTermName,
					V.VendorName AS VendorName
			FROM [dbo].[Vendor]  V WITH (NOLOCK) 
					LEFT JOIN [dbo].[CreditTerms] CR WITH (NOLOCK) ON CR.CreditTermsId = V.CreditTermsId
					LEFT JOIN [dbo].[VendorType] VT WITH (NOLOCK) ON VT.VendorTypeId = V.VendorTypeId
			WHERE  V.VendorId = @VendorId AND V.MasterCompanyId = @MasterCompanyId)

			SELECT * FROM Result;
		END
		ELSE
		BEGIN
			SELECT @CeraditLimit = V.CreditLimit,
				   @CreditTermsId = V.CreditTermsId,
				   @AccountType =  VT.[Description],
				   @AccountTypeId = V.VendorTypeId ,
				   @CreaditTerms = CR.[Name],
				   @VendorName = V.[VendorName]
			FROM [dbo].[Vendor] V WITH (NOLOCK) 
			LEFT JOIN [dbo].[CreditTerms] CR WITH (NOLOCK) ON CR.CreditTermsId = V.CreditTermsId
			LEFT JOIN [dbo].[VendorType] VT WITH (NOLOCK) ON VT.VendorTypeId = V.VendorTypeId
		    WHERE  V.VendorId = @VendorId AND V.MasterCompanyId = @MasterCompanyId

			IF(ISNULL(@ModuleId, 0) = ISNULL(@POModuleId, 0))
			BEGIN
				UPDATE PO
				SET 
					[CreditTermsId] = @CreditTermsId,
					[CreditLimit] =  @CeraditLimit,
					[Terms] = @CreaditTerms
				FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK)
				WHERE PO.PurchaseOrderId = @ReferenceId AND PO.VendorId = @VendorId AND PO.MasterCompanyId = @MasterCompanyId

				SELECT V.VendorTypeId as [AccountTypeId], PO.[CreditTermsId] AS CreditTermId, PO.[CreditLimit], PO.[VendorName], PO.[Terms] as [CreditTermName], VT.[Description] as [AccountTypeName] 
				FROM [dbo].[PurchaseOrder] PO WITH (NOLOCK)
				LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON PO.VendorId = V.VendorId
				LEFT JOIN [dbo].[VendorType] VT WITH (NOLOCK) ON VT.VendorTypeId = V.VendorTypeId
				WHERE PO.PurchaseOrderId = @ReferenceId AND PO.MasterCompanyId = @MasterCompanyId
			END
			ELSE IF(ISNULL(@ModuleId, 0) = ISNULL(@ROModuleId, 0))
			BEGIN
				UPDATE RO
				SET 
					[CreditTermsId] = @CreditTermsId,
					[CreditLimit] =  @CeraditLimit,
					[Terms] = @CreaditTerms
				FROM [dbo].[RepairOrder] RO WITH(NOLOCK)
				WHERE RO.RepairOrderId = @ReferenceId AND RO.VendorId = @VendorId AND RO.MasterCompanyId = @MasterCompanyId

				SELECT V.VendorTypeId as [AccountTypeId], RO.[CreditTermsId] AS CreditTermId, RO.[CreditLimit], RO.[VendorName], RO.[Terms] as [CreditTermName], VT.[Description] as [AccountTypeName] 
				FROM [dbo].[RepairOrder] RO WITH (NOLOCK)
				LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON RO.VendorId = V.VendorId
				LEFT JOIN [dbo].[VendorType] VT WITH (NOLOCK) ON VT.VendorTypeId = V.VendorTypeId
				WHERE RO.RepairOrderId = @ReferenceId AND RO.MasterCompanyId = @MasterCompanyId
			END		
			ELSE IF(ISNULL(@ModuleId, 0) = ISNULL(@RFQPOModuleId, 0))
			BEGIN
				UPDATE PO
				SET 
					[CreditTermsId] = @CreditTermsId,
					[CreditLimit] =  @CeraditLimit,
					[Terms] = @CreaditTerms
				FROM [dbo].[VendorRFQPurchaseOrder] PO WITH(NOLOCK)
				WHERE PO.VendorRFQPurchaseOrderId = @ReferenceId AND PO.VendorId = @VendorId AND PO.MasterCompanyId = @MasterCompanyId

				SELECT V.VendorTypeId as [AccountTypeId], PO.[CreditTermsId] AS CreditTermId, PO.[CreditLimit], PO.[VendorName], PO.[Terms] as [CreditTermName], VT.[Description] as [AccountTypeName] 
				FROM [dbo].[VendorRFQPurchaseOrder] PO WITH (NOLOCK)
				LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON PO.VendorId = V.VendorId
				LEFT JOIN [dbo].[VendorType] VT WITH (NOLOCK) ON VT.VendorTypeId = V.VendorTypeId
				WHERE PO.VendorRFQPurchaseOrderId = @ReferenceId AND PO.MasterCompanyId = @MasterCompanyId
			END	
			ELSE IF(ISNULL(@ModuleId, 0) = ISNULL(@RFQROModuleId, 0))
			BEGIN
				UPDATE RO
				SET 
					[CreditTermsId] = @CreditTermsId,
					[CreditLimit] =  @CeraditLimit,
					[Terms] = @CreaditTerms
				FROM [dbo].[VendorRFQRepairOrder] RO WITH(NOLOCK)
				WHERE RO.VendorRFQRepairOrderId = @ReferenceId AND RO.VendorId = @VendorId AND RO.MasterCompanyId = @MasterCompanyId

				SELECT V.VendorTypeId as [AccountTypeId], RO.[CreditTermsId] AS CreditTermId, RO.[CreditLimit], RO.[VendorName], RO.[Terms] as [CreditTermName], VT.[Description] as [AccountTypeName] 
				FROM [dbo].[VendorRFQRepairOrder] RO WITH (NOLOCK)
				LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON RO.VendorId = V.VendorId
				LEFT JOIN [dbo].[VendorType] VT WITH (NOLOCK) ON VT.VendorTypeId = V.VendorTypeId
				WHERE RO.VendorRFQRepairOrderId = @ReferenceId AND RO.MasterCompanyId = @MasterCompanyId
			END	
		END
		
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_Refresh_Vendor_CreditLimit_Terms' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName         = @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END