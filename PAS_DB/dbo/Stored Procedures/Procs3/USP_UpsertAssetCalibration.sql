
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <07/30/2021>  
** Description: <Upsert Asset Calibration>  
  
EXEC [dbo].[USP_UpsertAssetCalibration]
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1   08/07/2022  Hemant Saliya    Upsert Asset Calibration

EXEC [dbo].[USP_UpsertAssetCalibration] 
@AssetInventoryId=204,
@IsVenderOrInternal=0,
@VendorId=74,
@InternallyById=NULL,
@PerformedById=2,
@LastCalibrationDate=NULL,
@NextCalibrationDate=NULL,
@CalibrationMemo=N'<p>Calibration Notes</p>',
@CreatedBy=N'HAPPY CHANDIGARA'

**************************************************************/ 

CREATE PROCEDURE [dbo].[USP_UpsertAssetCalibration]  
@AssetInventoryId BIGINT, 
@IsVenderOrInternal BIT,
@VendorId BIGINT = NULL,
@InternallyById BIGINT = NULL,  
@PerformedById BIGINT = NULL, 
@CalibrationMemo VARCHAR(MAX) = NULL,
@CreatedBy VARCHAR(50) = NULL,
@CalibrationTypeId INT,
@LastCalibrationDate DATETIME = NULL,
@NextCalibrationDate DATETIME = NULL

AS
	BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		BEGIN
			
			IF EXISTS (SELECT TOP 1 *  FROM dbo.AssetInventory WITH (NOLOCK) WHERE AssetInventoryId=@AssetInventoryId  AND CalibrationRequired=1)  
			BEGIN  
				IF EXISTS (SELECT TOP 1  * FROM dbo.CalibrationManagment WITH (NOLOCK) WHERE AssetInventoryId=@AssetInventoryId AND CalibrationTypeId = @CalibrationTypeId)   --AND IsActive=1 
				BEGIN  
					DELETE FROM dbo.CalibrationManagment WHERE AssetInventoryId=@AssetInventoryId AND CalibrationTypeId = @CalibrationTypeId --AND IsActive=1  
				END  
				INSERT INTO [dbo].[CalibrationManagment]  
					([AssetRecordId] ,[LastCalibrationDate],[NextCalibrationDate],[LastCalibrationBy],  
					 [VendorId],[VendorName],[CalibrationDate],[CurrencyId], CurrencyName, [UnitCost], [CertifyType],[MasterCompanyId],  
					 [IsDeleted],[IsActive] ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],  
					 [EmployeeId],[InternallyById],[EmployeeName],[InternallyBy],[IsVendororEmployee],[AssetInventoryId],[CalibrationTypeId]) 
				SELECT AI.AssetRecordId, @LastCalibrationDate,  @NextCalibrationDate,					
					@CreatedBy,@VendorId, V.VendorName, GETDATE(),AI.CurrencyId, C.Code, AI.UnitCost,
					CASE WHEN @CalibrationTypeId = 1 THEN 'Calibration'
						 WHEN @CalibrationTypeId = 2 THEN 'Certification'
						 WHEN @CalibrationTypeId = 3 THEN 'Inspection'
						 WHEN @CalibrationTypeId = 4 THEN 'Verification'
					END,
					AI.MasterCompanyId,  
					0,1,@CreatedBy,@CreatedBy,GETDATE(),GETDATE(),					
					@PerformedById,
					@InternallyById,
					CASE WHEN ISNULL(@InternallyById, 0) != 0 THEN EMPI.FirstName + ' ' + EMPI.LastName ELSE NULL END,
					CASE WHEN ISNULL(@PerformedById, 0) != 0 THEN EMPP.FirstName + ' ' + EMPP.LastName ELSE NULL END,
					CASE WHEN @IsVenderOrInternal = 1 THEN 'vendor' ELSE 'internal' END ,AI.AssetInventoryId,@CalibrationTypeId  
				FROM dbo.AssetInventory As AI WITH(NOLOCK)  
					LEFT JOIN dbo.Vendor V WITH(NOLOCK) ON V.VendorId = @VendorId
					LEFT JOIN dbo.Currency C WITH(NOLOCK) ON C.CurrencyId = AI.CurrencyId
					LEFT JOIN dbo.Employee EMPI WITH(NOLOCK) ON EMPI.EmployeeId = @InternallyById
					LEFT JOIN dbo.Employee EMPP WITH(NOLOCK) ON EMPP.EmployeeId = @PerformedById
				WHERE AI.AssetInventoryId=@AssetInventoryId  
			END 		
		END
	COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpsertAssetCalibration' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AssetInventoryId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID				= @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END