/*************************************************************           
 ** File:   [USP_VendorPayment_AddUpdateVendorCreditMemo]           
 ** Author: AMIT GHEDIYA
 ** Description: This stored procedure is used to Add & Update Vendor RMA Details
 ** Date:   09/22/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    09/22/2023   AMIT GHEDIYA     Created

*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorPayment_AddUpdateVendorCreditMemo]
@tbl_VendorCreditMemoMapping VendorCreditMemoMappingType READONLY,
@IsAllDelete BIT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY    
	BEGIN TRANSACTION

		DECLARE @VendorCreditMemoId BIGINT,@MasterLoopID INT,@VendorId BIGINT;

		IF OBJECT_ID(N'tempdb..#tmpVendorCreditMemoMapping') IS NOT NULL
		BEGIN
			DROP TABLE #tmpVendorCreditMemoMapping
		END
				
		CREATE TABLE #tmpVendorCreditMemoMapping
		(
			[ID] INT IDENTITY,
			[VendorCreditMemoMappingId] INT,
			[VendorCreditMemoId] BIGINT NULL,
			[VendorPaymentDetailsId] BIGINT NULL,
			[VendorId] BIGINT NULL,
			[Amount] DECIMAL(18,2) NULL,
			[MasterCompanyId] INT NOT NULL,
			[CreatedBy] VARCHAR(50) NOT NULL,
			[CreatedDate] DATETIME NOT NULL,
			[UpdatedBy] VARCHAR(50) NULL,
			[UpdatedDate] DATETIME NULL,
			[IsActive] BIT NOT NULL,
			[IsDeleted] BIT NOT NULL,
			[InvoiceType] INT NULL
		)

		DECLARE @VendorCreditMemoMappingId BIGINT,
				@VendorPaymentDetailsId BIGINT;

		SELECT @VendorPaymentDetailsId = VendorPaymentDetailsId, @VendorCreditMemoId = VendorCreditMemoId FROM @tbl_VendorCreditMemoMapping;

		IF(@IsAllDelete = 1)
		BEGIN
			DELETE [dbo].[VendorCreditMemoMapping]  WHERE [VendorPaymentDetailsId] = @VendorPaymentDetailsId;
		END
		ELSE
		BEGIN
			IF(EXISTS(SELECT VendorPaymentDetailsId FROM [dbo].[VendorCreditMemoMapping] WITH (NOLOCK) WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId AND VendorCreditMemoId = @VendorCreditMemoId))
			BEGIN
				DELETE [dbo].[VendorCreditMemoMapping]  WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId;
			END
		 
			INSERT INTO [dbo].[VendorCreditMemoMapping]
			           ([VendorCreditMemoId],
					    [VendorPaymentDetailsId],
						[VendorId],
						[Amount],
						[MasterCompanyId],
						[CreatedBy],
						[CreatedDate],
						[UpdatedBy],
						[UpdatedDate],
						[IsActive],
						[IsDeleted],
						[InvoiceType])
				 SELECT [VendorCreditMemoId],
				        [VendorPaymentDetailsId],
						[VendorId],
						[Amount],
						[MasterCompanyId],
						[CreatedBy],
						[CreatedDate],
						[UpdatedBy],
						[UpdatedDate],
						[IsActive],
						[IsDeleted],
						[InvoiceType]
				  FROM @tbl_VendorCreditMemoMapping;

			SET  @VendorCreditMemoMappingId = @@IDENTITY;

			INSERT INTO #tmpVendorCreditMemoMapping ([VendorCreditMemoId],
					    [VendorPaymentDetailsId],
						[VendorId],
						[Amount],
						[MasterCompanyId],
						[CreatedBy],
						[CreatedDate],
						[UpdatedBy],
						[UpdatedDate],
						[IsActive],
						[IsDeleted],
						[InvoiceType])
				SELECT  [VendorCreditMemoId],
				        [VendorPaymentDetailsId],
						[VendorId],
						[Amount],
						[MasterCompanyId],
						[CreatedBy],
						[CreatedDate],
						[UpdatedBy],
						[UpdatedDate],
						[IsActive],
						[IsDeleted],
						[InvoiceType]
				FROM @tbl_VendorCreditMemoMapping


			SELECT  @MasterLoopID = MAX(ID) FROM #tmpVendorCreditMemoMapping
			WHILE(@MasterLoopID > 0)
			BEGIN
				SELECT @VendorCreditMemoId = [VendorCreditMemoId] , @VendorId = VendorId
				FROM #tmpVendorCreditMemoMapping WHERE [ID] = @MasterLoopID;
				--[dbo].[VendorCreditMemoMapping] WITH (NOLOCK) 
				--WHERE VendorCreditMemoMappingId = @VendorCreditMemoMappingId;

				----Reserve CreditMemo for Used
				--UPDATE [dbo].[VendorCreditMemo] SET IsVendorPayment = 1
				--WHERE VendorCreditMemoId = @VendorCreditMemoId;

				----Reserve ManualJournalDetails for Used
				--UPDATE [dbo].[ManualJournalDetails] SET IsVendorPayment = 1
				--WHERE ManualJournalHeaderId = @VendorCreditMemoId AND ReferenceId = @VendorId;

				SET @VendorCreditMemoId = 0;
				SET @VendorId = 0;
				SET @MasterLoopID = @MasterLoopID - 1;
			END
		END

		SELECT [VendorCreditMemoId]
			  ,[VendorPaymentDetailsId]
			  ,[VendorId]
			  ,[Amount]
		FROM [dbo].[VendorCreditMemoMapping] WITH (NOLOCK) WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId;

		--SELECT @VendorCreditMemoMappingId AS VendorCreditMemoMappingId;

	COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_VendorPayment_AddUpdateVendorCreditMemo]'			
			,@ProcedureParameters VARCHAR(3000) = ''				 
            ,@ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END