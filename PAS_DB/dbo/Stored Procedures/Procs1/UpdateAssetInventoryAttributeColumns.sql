/*************************************************************
 ** File:   [GetAssetDetailsByInventoryID]
 ** Author:   Abhishek Jirawla
 ** Description: This stored procedure is used to Update Asset Inventory Attribute Columns
 ** Purpose:
 ** Date:    UNKNOWN

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				--------------------------------
    1    UNKNOWN	   UNKNOWN				Created
	2	 29-07-2026	  Abhishek Jirawala		Asset.AssetAttributeTypeId now always stores an AssetAttributeTypeId
											(never a DeprNonDeprTangibleAssetsId); joined dnta by its
											AssetAttributeTypeId FK instead of its own PK. Dropped the
											dnta.AssetAttributeTypeName fallback (column removed) - asty is now
											always joined so its name always resolves.
	3	01-08-2026	  Sumit Kumar			Added required fields [PN-17523]
	4	 29-07-2026	  Abhishek Jirawala		Adding Tangible Class Id

--  EXEC [UpdateAssetInventoryAttributeColumns] 1123
**************************************************************/
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
			Declare @AssetClassSource varchar(30) = NULL

			select @IsIntangible = IsIntangible from dbo.Asset WITH(NOLOCK)  where AssetRecordId= @AssetRecordId
			select @AssetClassSource = AssetClassSource from dbo.Asset WITH(NOLOCK) where AssetRecordId = @AssetRecordId

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

				if (@AssetClassSource = 'DeprNonDeprTangibleAssets')
				BEGIN

					Update AI SET
						AI.AcquiredGLAccountId = DNTA.AcquiredGLAccountId,
						AI.AcquiredGLAccountName = GLAQ.AccountCode +'-'+ GLAQ.AccountName,
						AI.DeprExpenseGLAccountId = DNTA.DeprExpenseGLAccountId,
						AI.DeprExpenseGLAccountName = GLD.AccountCode +'-'+ GLD.AccountName,
						AI.AdDepsGLAccountId = DNTA.AccumDeprGLAccountId,
						AI.AdDepsGLAccountName = GLAD.AccountCode +'-'+ GLAD.AccountName,
						AI.CalibratedGLAccountId = DNTA.CalibratedGLAccountId,
						AI.CalibratedGLAccountName = GLC.AccountCode +'-'+ GLC.AccountName,
						AI.AssetSaleGLAccountId = DNTA.AssetSaleGLAccountId,
						AI.AssetSaleGLAccountName = GLS.AccountCode +'-'+ GLS.AccountName,
						AI.AssetWriteOffGLAccountId = DNTA.AssetWriteOffGLAccountId,
						AI.AssetWriteOffGLAccountName = GLO.AccountCode +'-'+ GLO.AccountName,
						AI.AssetWriteDownGLAccountId = DNTA.AssetWriteDownGLAccountId,
						AI.AssetWriteDownGLAccountName = GLDO.AccountCode +'-'+ GLDO.AccountName,
						AI.DepreciationMethodId = Dmethod.AssetDepreciationMethodId,
						AI.DepreciationMethodName = Dmethod.AssetDepreciationMethodName,
						AI.AssetLife = ISNULL(DNTA.AssetLife, 0),
						AI.ResidualPercentageId = dnta.ResidualPercentage,
						AI.ResidualPercentage = ISNULL(per.PercentValue, 0),
						AI.DepreciationFrequencyId = ISNULL(dnta.DepreciationFrequencyId,0),
						AI.DepreciationFrequencyName = ISNULL(asdf.Name, ''),
						AI.TangibleClassId = ISNULL(DNTA.TangibleClassId, AI.TangibleClassId)
					FROM [dbo].[AssetInventory] AI WITH (NOLOCK)
						LEFT JOIN dbo.Asset Asset WITH (NOLOCK) ON Asset.AssetRecordId = AI.AssetRecordId
						LEFT JOIN dbo.DeprNonDeprTangibleAssets DNTA WITH (NOLOCK) ON DNTA.TangibleClassId = Asset.TangibleClassId
						LEFT JOIN dbo.GLAccount GLD WITH (NOLOCK) ON GLD.GLAccountId = DNTA.DeprExpenseGLAccountId
						LEFT JOIN dbo.GLAccount GLAD WITH (NOLOCK) ON GLAD.GLAccountId = DNTA.AccumDeprGLAccountId
						LEFT JOIN dbo.GLAccount GLC WITH (NOLOCK) ON GLC.GLAccountId = DNTA.CalibratedGLAccountId
						LEFT JOIN dbo.GLAccount GLAQ WITH (NOLOCK) ON GLAQ.GLAccountId = DNTA.AcquiredGLAccountId
						LEFT JOIN dbo.GLAccount GLS WITH (NOLOCK) ON GLS.GLAccountId = DNTA.AssetSaleGLAccountId
						LEFT JOIN dbo.GLAccount GLO WITH (NOLOCK) ON GLO.GLAccountId = DNTA.AssetWriteOffGLAccountId
						LEFT JOIN dbo.GLAccount GLDO WITH (NOLOCK) ON GLDO.GLAccountId = DNTA.AssetWriteDownGLAccountId
						LEFT JOIN dbo.AssetDepreciationMethod Dmethod WITH (NOLOCK) ON Dmethod.AssetDepreciationMethodId = DNTA.AssetDeprMethodId
						LEFT JOIN dbo.[Percent] per WITH (NOLOCK) ON dnta.ResidualPercentage = per.PercentId
						LEFT JOIN dbo.AssetDepreciationFrequency asdf WITH (NOLOCK) ON dnta.DepreciationFrequencyId = asdf.AssetDepreciationFrequencyId
					
					WHERE AI.AssetInventoryId = @AssetInventoryId
				END
				ELSE
				BEGIN

				   Update AI SET
						AI.DepreciationMethodId = Dmethod.AssetDepreciationMethodId,
						AI.DepreciationMethodName = Dmethod.AssetDepreciationMethodName,
						AI.AssetLife = ISNULL(DNTA.AssetLife, 0),
						AI.ResidualPercentageId = dnta.ResidualPercentage,
						AI.ResidualPercentage = per.PercentValue,
						AI.DepreciationFrequencyId = dnta.DepreciationFrequencyId,
						AI.DepreciationFrequencyName = Fre.Name,

						AI.AcquiredGLAccountId = DNTA.AcquiredGLAccountId,
						AI.AcquiredGLAccountName = GLA.AccountCode +'-'+ GLA.AccountName,
						AI.DeprExpenseGLAccountId = DNTA.DeprExpenseGLAccountId,
						AI.DeprExpenseGLAccountName = GLD.AccountCode +'-'+ GLD.AccountName,
						AI.AdDepsGLAccountId = DNTA.AccumDeprGLAccountId,
						AI.AdDepsGLAccountName = GLAD.AccountCode +'-'+ GLAD.AccountName,

					    AI.AssetSaleGLAccountId =DNTA.AssetSaleGLAccountId,
						AI.AssetSaleGLAccountName = GLS.AccountCode +'-'+ GLS.AccountName,
						AI.AssetWriteOffGLAccountId =DNTA.AssetWriteOffGLAccountId,
						AI.AssetWriteOffGLAccountName = GLO.AccountCode +'-'+ GLO.AccountName,
						AI.AssetWriteDownGLAccountId = DNTA.AssetWriteDownGLAccountId,
						AI.AssetWriteDownGLAccountName = GLDO.AccountCode +'-'+ GLDO.AccountName,
						AI.TangibleClassId = ISNULL(DNTA.TangibleClassId, AI.TangibleClassId)

				    FROM [dbo].[AssetInventory] AI WITH (NOLOCK)
						LEFT JOIN dbo.Asset Asset WITH (NOLOCK) ON Asset.AssetRecordId = AI.AssetRecordId
						LEFT JOIN dbo.DeprNonDeprTangibleAssets DNTA WITH (NOLOCK) ON DNTA.TangibleClassId = Asset.TangibleClassId

						--LEFT JOIN dbo.AssetAttributeType ATTB WITH (NOLOCK) ON ATTB.AssetAttributeTypeId = Asset.AssetAttributeTypeId
						LEFT JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = DNTA.AcquiredGLAccountId
						LEFT JOIN dbo.GLAccount GLD WITH (NOLOCK) ON GLD.GLAccountId = DNTA.DeprExpenseGLAccountId
						LEFT JOIN dbo.GLAccount GLAD WITH (NOLOCK) ON GLAD.GLAccountId = DNTA.AccumDeprGLAccountId
						LEFT JOIN dbo.GLAccount GLS WITH (NOLOCK) ON GLS.GLAccountId = DNTA.AssetSaleGLAccountId
						LEFT JOIN dbo.GLAccount GLO WITH (NOLOCK) ON GLO.GLAccountId = DNTA.AssetWriteOffGLAccountId
						LEFT JOIN dbo.GLAccount GLDO WITH (NOLOCK) ON GLDO.GLAccountId = DNTA.AssetWriteDownGLAccountId
						LEFT JOIN dbo.AssetDepreciationMethod Dmethod WITH (NOLOCK) ON Dmethod.AssetDepreciationMethodId = dnta.AssetDeprMethodId
						LEFT JOIN dbo.[Percent] per WITH (NOLOCK) ON per.PercentId = dnta.ResidualPercentage
						LEFT JOIN dbo.AssetDepreciationFrequency Fre WITH (NOLOCK) ON Fre.AssetDepreciationFrequencyId = dnta.DepreciationFrequencyId
					WHERE AI.AssetInventoryId = @AssetInventoryId
				END
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