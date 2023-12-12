/*************************************************************
EXEC [dbo].[GetMigrationDataCount] 2, 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetMigrationDataCount]
	@MasterCompanyId BIGINT = NULL,
	@ModuleId INT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN
		DECLARE @ProcessedCnts INT = 0;
		DECLARE @MigratedCnts INT = 0;
		DECLARE @FailedCnts INT = 0;
		DECLARE @ExistsCnts INT = 0;

		IF (@ModuleId = 1) -- Customer
		BEGIN
			SELECT @ProcessedCnts = COUNT(C.CustomerId) FROM Quantum_Staging.DBO.Customers C WITH (NOLOCK) WHERE C.MasterCompanyId = @MasterCompanyId;

			SELECT @MigratedCnts = COUNT(C.CustomerId) FROM Quantum_Staging.DBO.Customers C WITH (NOLOCK)
			WHERE C.Migrated_Id IS NOT NULL AND C.MasterCompanyId = @MasterCompanyId;

			SELECT @FailedCnts = COUNT(C.CustomerId) FROM Quantum_Staging.DBO.Customers C WITH (NOLOCK)
			WHERE C.Migrated_Id IS NULL AND (C.ErrorMsg IS NOT NULL AND C.ErrorMsg NOT like '%Customer already exists%') AND C.MasterCompanyId = @MasterCompanyId;

			SELECT @ExistsCnts = COUNT(C.CustomerId) FROM Quantum_Staging.DBO.Customers C WITH (NOLOCK)
			WHERE C.ErrorMsg like '%Customer already exists%' AND C.MasterCompanyId = @MasterCompanyId;
			
			SELECT @ProcessedCnts AS Processed, @MigratedCnts AS Migrated, @FailedCnts AS Failed, @ExistsCnts AS Exist;
		END
		ELSE IF (@ModuleId = 2) -- Vendor
		BEGIN
			SELECT @ProcessedCnts = COUNT(V.VendorId) FROM Quantum_Staging.DBO.Vendors V WITH (NOLOCK) WHERE V.MasterCompanyId = @MasterCompanyId;

			SELECT @MigratedCnts = COUNT(V.VendorId) FROM Quantum_Staging.DBO.Vendors V WITH (NOLOCK)
			WHERE V.Migrated_Id IS NOT NULL AND V.MasterCompanyId = @MasterCompanyId;

			SELECT @FailedCnts = COUNT(V.VendorId) FROM Quantum_Staging.DBO.Vendors V WITH (NOLOCK)
			WHERE V.Migrated_Id IS NULL AND (V.ErrorMsg IS NOT NULL AND V.ErrorMsg NOT like '%Vendor already exists%') AND V.MasterCompanyId = @MasterCompanyId;

			SELECT @ExistsCnts = COUNT(V.VendorId) FROM Quantum_Staging.DBO.Vendors V WITH (NOLOCK)
			WHERE V.ErrorMsg like '%Vendor already exists%' AND V.MasterCompanyId = @MasterCompanyId;
			
			SELECT @ProcessedCnts AS Processed, @MigratedCnts AS Migrated, @FailedCnts AS Failed, @ExistsCnts AS Exist;
		END
		ELSE IF (@ModuleId = 20) -- Item Master
		BEGIN
			SELECT @ProcessedCnts = COUNT(IM.ItemMasterId) FROM Quantum_Staging.DBO.ItemMasters IM WITH (NOLOCK) WHERE IM.MasterCompanyId = @MasterCompanyId;

			SELECT @MigratedCnts = COUNT(IM.ItemMasterId) FROM Quantum_Staging.DBO.ItemMasters IM WITH (NOLOCK)
			WHERE IM.Migrated_Id IS NOT NULL AND IM.MasterCompanyId = @MasterCompanyId;

			SELECT @FailedCnts = COUNT(IM.ItemMasterId) FROM Quantum_Staging.DBO.ItemMasters IM WITH (NOLOCK)
			WHERE IM.Migrated_Id IS NULL AND (IM.ErrorMsg IS NOT NULL AND IM.ErrorMsg NOT like '%Item Master record already exists%') AND IM.MasterCompanyId = @MasterCompanyId;

			SELECT @ExistsCnts = COUNT(IM.ItemMasterId) FROM Quantum_Staging.DBO.ItemMasters IM WITH (NOLOCK)
			WHERE IM.ErrorMsg like '%Item Master record already exists%' AND IM.MasterCompanyId = @MasterCompanyId;
			
			SELECT @ProcessedCnts AS Processed, @MigratedCnts AS Migrated, @FailedCnts AS Failed, @ExistsCnts AS Exist;
		END
		ELSE IF (@ModuleId = 22) -- Stockline
		BEGIN
			SELECT @ProcessedCnts = COUNT(Stk.StocklineId) FROM Quantum_Staging.DBO.Stocklines Stk WITH (NOLOCK) WHERE Stk.MasterCompanyId = @MasterCompanyId;

			SELECT @MigratedCnts = COUNT(Stk.StocklineId) FROM Quantum_Staging.DBO.Stocklines Stk WITH (NOLOCK)
			WHERE Stk.Migrated_Id IS NOT NULL AND Stk.MasterCompanyId = @MasterCompanyId;

			SELECT @FailedCnts = COUNT(Stk.StocklineId) FROM Quantum_Staging.DBO.Stocklines Stk WITH (NOLOCK)
			WHERE Stk.Migrated_Id IS NULL AND (Stk.ErrorMsg IS NOT NULL AND Stk.ErrorMsg NOT like '%Stockline record already exists%') AND Stk.MasterCompanyId = @MasterCompanyId;

			SELECT @ExistsCnts = COUNT(Stk.StocklineId) FROM Quantum_Staging.DBO.Stocklines Stk WITH (NOLOCK)
			WHERE Stk.ErrorMsg like '%Stockline record already exists%' AND Stk.MasterCompanyId = @MasterCompanyId;
			
			SELECT @ProcessedCnts AS Processed, @MigratedCnts AS Migrated, @FailedCnts AS Failed, @ExistsCnts AS Exist;
		END
	END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments VARCHAR(150) = 'GetMigrationDataCount' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '
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