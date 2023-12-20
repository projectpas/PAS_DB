CREATE    PROCEDURE [dbo].[UpdateAssetInventoryAttributeColumns]
	@AssetInventoryId int,
	@AssetRecordId int
	
AS
BEGIN
	   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	   SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			Declare @IsIntangible bit =0

			select @IsIntangible = IsIntangible from Asset  where AssetRecordId= @AssetRecordId

			if(@IsIntangible =1)
			begin

			    Update AI SET 					
					AI.DepreciationMethodId = Dmethod.AssetDepreciationMethodId,
					AI.DepreciationMethodName = Dmethod.AssetDepreciationMethodName,
					AI.DepreciationFrequencyId = ATTB.AssetAmortizationIntervalId,
					AI.DepreciationFrequencyName = Fre.Name,

					AI.IntangibleGLAccountId = ATTB.IntangibleGLAccountId,
					AI.IntangibleGLAccountName = GLA.AccountCode +'-'+ GLA.AccountName,
					AI.AmortExpenseGLAccountId = ATTB.AmortExpenseGLAccountId,
					AI.AmortExpenseGLAccountName = GLD.AccountCode +'-'+ GLD.AccountName,
					AI.AccAmortDeprGLAccountId = ATTB.AccAmortDeprGLAccountId,
					AI.AccAmortDeprGLAccountName = GLAD.AccountCode +'-'+ GLAD.AccountName,

					AI.IntangibleWriteDownGLAccountId =ATTB.IntangibleWriteDownGLAccountId,
					AI.IntangibleWriteDownGLAccountName = GLO.AccountCode +'-'+ GLO.AccountName,
					AI.IntangibleWriteOffGLAccountId = ATTB.IntangibleWriteOffGLAccountId,
					AI.IntangibleWriteOffGLAccountName = GLDO.AccountCode +'-'+ GLDO.AccountName

			    FROM [dbo].[AssetInventory] AI WITH (NOLOCK)
					LEFT JOIN dbo.Asset Asset WITH (NOLOCK) ON Asset.AssetRecordId = AI.AssetRecordId
					LEFT JOIN dbo.AssetIntangibleAttributeType ATTB WITH (NOLOCK) ON ATTB.AssetIntangibleTypeId = Asset.AssetIntangibleTypeId
					LEFT JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = ATTB.IntangibleGLAccountId
					LEFT JOIN dbo.GLAccount GLD WITH (NOLOCK) ON GLD.GLAccountId = ATTB.AmortExpenseGLAccountId
					LEFT JOIN dbo.GLAccount GLAD WITH (NOLOCK) ON GLAD.GLAccountId = ATTB.AccAmortDeprGLAccountId
					LEFT JOIN dbo.GLAccount GLO WITH (NOLOCK) ON GLO.GLAccountId = ATTB.IntangibleWriteOffGLAccountId
					LEFT JOIN dbo.GLAccount GLDO WITH (NOLOCK) ON GLDO.GLAccountId = ATTB.IntangibleWriteDownGLAccountId
					LEFT JOIN dbo.AssetDepreciationMethod Dmethod WITH (NOLOCK) ON Dmethod.AssetDepreciationMethodId = ATTB.AssetDepreciationMethodId
					LEFT JOIN dbo.AssetDepreciationFrequency Fre WITH (NOLOCK) ON Fre.AssetDepreciationFrequencyId = ATTB.AssetAmortizationIntervalId
				WHERE AI.AssetInventoryId = @AssetInventoryId
			END
			else
			BEGIN

			   Update AI SET 					
					AI.DepreciationMethodId = Dmethod.AssetDepreciationMethodId,
					AI.DepreciationMethodName = Dmethod.AssetDepreciationMethodName,
					AI.ResidualPercentageId = per.PercentId,
					AI.ResidualPercentage = per.PercentValue,
					AI.DepreciationFrequencyId = ATTB.DepreciationFrequencyId,
					AI.DepreciationFrequencyName = Fre.Name,

					AI.AcquiredGLAccountId = ATTB.AcquiredGLAccountId,
					AI.AcquiredGLAccountName = GLA.AccountCode +'-'+ GLA.AccountName,
					AI.DeprExpenseGLAccountId = ATTB.DeprExpenseGLAccountId,
					AI.DeprExpenseGLAccountName = GLD.AccountCode +'-'+ GLD.AccountName,
					AI.AdDepsGLAccountId = ATTB.AdDepsGLAccountId,
					AI.AdDepsGLAccountName = GLAD.AccountCode +'-'+ GLAD.AccountName,

				    AI.AssetSaleGLAccountId =ATTB.AssetSale,
					AI.AssetSaleGLAccountName = GLS.AccountCode +'-'+ GLS.AccountName,
					AI.AssetWriteOffGLAccountId =ATTB.AssetWriteOff,
					AI.AssetWriteOffGLAccountName = GLO.AccountCode +'-'+ GLO.AccountName,
					AI.AssetWriteDownGLAccountId = ATTB.AssetWriteDown,
					AI.AssetWriteDownGLAccountName = GLDO.AccountCode +'-'+ GLDO.AccountName,
					AI.AssetAttributeTypeId = ATTB.AssetAttributeTypeId

			    FROM [dbo].[AssetInventory] AI WITH (NOLOCK)
					LEFT JOIN dbo.Asset Asset WITH (NOLOCK) ON Asset.AssetRecordId = AI.AssetRecordId
					LEFT JOIN dbo.AssetAttributeType ATTB WITH (NOLOCK) ON ATTB.AssetAttributeTypeId = Asset.AssetAttributeTypeId
					LEFT JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = ATTB.AcquiredGLAccountId
					LEFT JOIN dbo.GLAccount GLD WITH (NOLOCK) ON GLD.GLAccountId = ATTB.DeprExpenseGLAccountId
					LEFT JOIN dbo.GLAccount GLAD WITH (NOLOCK) ON GLAD.GLAccountId = ATTB.AdDepsGLAccountId
					LEFT JOIN dbo.GLAccount GLS WITH (NOLOCK) ON GLS.GLAccountId = ATTB.AssetSale
					LEFT JOIN dbo.GLAccount GLO WITH (NOLOCK) ON GLO.GLAccountId = ATTB.AssetWriteOff
					LEFT JOIN dbo.GLAccount GLDO WITH (NOLOCK) ON GLDO.GLAccountId = ATTB.AssetWriteDown
					LEFT JOIN dbo.AssetDepreciationMethod Dmethod WITH (NOLOCK) ON Dmethod.AssetDepreciationMethodId = ATTB.DepreciationMethod
					LEFT JOIN dbo.[Percent] per WITH (NOLOCK) ON per.PercentId = ATTB.ResidualPercentage
					LEFT JOIN dbo.AssetDepreciationFrequency Fre WITH (NOLOCK) ON Fre.AssetDepreciationFrequencyId = ATTB.DepreciationFrequencyId
				WHERE AI.AssetInventoryId = @AssetInventoryId
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
              , @AdhocComments     VARCHAR(150)    = 'UpdateAssetInventoryAttributeColumns' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AssetInventoryId, '') + ''
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