/*************************************************************           
 ** File:   [USP_StandAloneCreditMemoDetails_AddUpdate]           
 ** Author: AMIT GHEDIYA
 ** Description: This stored procedure is used to Add & Update Stand Alone Credit Memo Details
 ** Date:   09/01/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		  Change Description            
 ** --   --------     -------		  ---------------------------     
    1    09/01/2023   AMIT GHEDIYA     Created
	2    09/05/2023   AMIT GHEDIYA     Updated for add Reason in details table.
	3    09/12/2023   AMIT GHEDIYA     Updated for add LE in details table.
	4    09/15/2023   AMIT GHEDIYA     Updated for add for ManagementStructureDetails.
	5    09/25/2023   AMIT GHEDIYA     Updated for Clear PDF path when new Item added.
	6    03/25/2023   Devendra Shekh   added CustomerCreditPaymentDetailId

*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_StandAloneCreditMemoDetails_AddUpdate]
	@CreditMemoHeaderId BIGINT,
	@CreatedBy VARCHAR(50),
	@UpdatedBy VARCHAR(50),
	@MasterCompanyId INT,
	@StandAloneCreditMemoDetails StandAloneCreditMemoDetailsType READONLY
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY    
	BEGIN TRANSACTION

		DECLARE @MasterLoopID INT,
				@StandAloneCreditMemoDetailId BIGINT,
				@GlAccountId BIGINT,
				@Reason VARCHAR(MAX),
				@Qty INT,
				@Rate DECIMAL(18,2),
				@Amount DECIMAL(18,2),
				@IsDeleted BIT,
				@FinalAmount Decimal(18,2),
				@StandAloneCreditMemoDetailsId BIGINT,
				@ManagementStructureId BIGINT,
				@LastMSLevel VARCHAR(256),
				@AllMSlevels VARCHAR(256),
				@ExistindStatusId INT,
				@StatusId INT,
				@StatusName VARCHAR(50),
				@PendingStatusId INT,
				@PendingStatusName VARCHAR(50),
				@ModuleId INT,
				@CustomerCreditPaymentDetailId BIGINT = NULL;

		SELECT @ModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName='StandAloneCreditMemoDetails';

		--Get statusId
		SELECT @StatusId = Id, @StatusName = Name FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE Name = 'Fulfilling';
		SELECT @PendingStatusId = Id, @PendingStatusName = Name FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE Name = 'Pending';
	
	    IF OBJECT_ID(N'tempdb..#tmpStandAloneCreditMemoDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmpStandAloneCreditMemoDetails
		END
				
		CREATE TABLE #tmpStandAloneCreditMemoDetails
		(
			[ID] INT IDENTITY,
			[StandAloneCreditMemoDetailId] BIGINT NULL,
			[GlAccountId] [bigint] NOT NULL,
			[Reason] [varchar](max) NOT NULL,
			[Qty] [int] NOT NULL,
			[Rate] [decimal](18, 2) NOT NULL,
			[Amount] [decimal](18, 2) NOT NULL,
			[IsDeleted] [bit] NOT NULL,
			[ManagementStructureId] [bigint] NULL,
			[LastMSLevel] [varchar](256) NULL,
			[AllMSlevels] [varchar](256) NULL,
			[CustomerCreditPaymentDetailId] [bigint] NULL,
		)

		INSERT INTO #tmpStandAloneCreditMemoDetails ([StandAloneCreditMemoDetailId],[GlAccountId],[Reason],[Qty],[Rate],[Amount],[IsDeleted],
													 [ManagementStructureId],[LastMSLevel],[AllMSlevels],[CustomerCreditPaymentDetailId])
		SELECT [StandAloneCreditMemoDetailId],[GlAccountId],[Reason],[Qty],[Rate],[Amount],[IsDeleted], 
													[ManagementStructureId],[LastMSLevel],[AllMSlevels],[CustomerCreditPaymentDetailId] FROM @StandAloneCreditMemoDetails;

		SELECT  @MasterLoopID = MAX(ID) FROM #tmpStandAloneCreditMemoDetails

		WHILE(@MasterLoopID > 0)
		BEGIN
			SELECT @StandAloneCreditMemoDetailId = [StandAloneCreditMemoDetailId],
				   @GlAccountId = [GlAccountId],
				   @Reason = [Reason],
				   @Qty = [Qty],
				   @Rate = [Rate],
				   @Amount = [Amount],
				   @IsDeleted = IsDeleted,
				   @ManagementStructureId = ManagementStructureId,
				   @LastMSLevel = LastMSLevel,
				   @AllMSlevels = AllMSlevels,
				   @CustomerCreditPaymentDetailId = [CustomerCreditPaymentDetailId]
			FROM #tmpStandAloneCreditMemoDetails WHERE [ID] = @MasterLoopID;
			
			IF(@StandAloneCreditMemoDetailId = 0)
			BEGIN 
				--Checking if already fullfill then need to set pending status for CM.
				SELECT @ExistindStatusId = StatusId FROM [dbo].[CreditMemo] WITH(NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoHeaderId;
				
				--Update status to Pending if new Item added
				IF(@StatusId = @ExistindStatusId)
				BEGIN
					UPDATE [dbo].[CreditMemo] SET StatusId = @PendingStatusId, Status = @PendingStatusName WHERE CreditMemoHeaderId = @CreditMemoHeaderId;
				END

				INSERT INTO [dbo].[StandAloneCreditMemoDetails]([CreditMemoHeaderId],[GlAccountId],[Reason],[Qty],[Rate],[Amount]
															,[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
															[ManagementStructureId],[LastMSLevel],[AllMSlevels], [CustomerCreditPaymentDetailId])
							        SELECT @CreditMemoHeaderId,@GlAccountId,@Reason,@Qty,@Rate,@Amount
											,@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
											@ManagementStructureId,@LastMSLevel,@AllMSlevels,@CustomerCreditPaymentDetailId;

				SELECT @StandAloneCreditMemoDetailsId = SCOPE_IDENTITY();

				--Add into PROCAddUpdateCustomerRMAMSData
				EXEC PROCAddUpdateCustomerRMAMSData @StandAloneCreditMemoDetailsId,@ManagementStructureId,@MasterCompanyId,@CreatedBy,@UpdatedBy,@ModuleId,1,0
				
				-- Add in batch details
				--EXEC [dbo].[USP_StandAloneCM_PostCheckBatchDetails] @StandAloneCreditMemoDetailsId,@CreditMemoHeaderId,@Amount,@MasterCompanyId,@UpdatedBy;
			END
			ELSE IF(@StandAloneCreditMemoDetailId > 0)
			BEGIN 
				UPDATE [dbo].[StandAloneCreditMemoDetails] 
				SET [CreditMemoHeaderId] = @CreditMemoHeaderId,
					[GlAccountId] = @GlAccountId,
					[Reason] = @Reason,
					[Qty] = @Qty,
					[Rate] = @Rate,
					[Amount] = @Amount,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE(),
					[ManagementStructureId] = @ManagementStructureId,
					[LastMSLevel] = @LastMSLevel,
					[AllMSlevels] = @AllMSlevels
				WHERE StandAloneCreditMemoDetailId = @StandAloneCreditMemoDetailId;

				--Update Existing PROCAddUpdateCustomerRMAMSData
				EXEC PROCAddUpdateCustomerRMAMSData @StandAloneCreditMemoDetailId,@ManagementStructureId,@MasterCompanyId,@CreatedBy,@UpdatedBy,@ModuleId,2,0
			END

			--Delete detail records
			IF(@IsDeleted > 0)
			BEGIN
				UPDATE [dbo].[StandAloneCreditMemoDetails] SET IsActive = 0,IsDeleted = 1 
				WHERE StandAloneCreditMemoDetailId = @StandAloneCreditMemoDetailId;
			END

			SET @MasterLoopID = @MasterLoopID - 1;
	   END

	   --Update Amount into header table
		SELECT @FinalAmount = SUM(Amount) FROM [dbo].[StandAloneCreditMemoDetails] WITH(NOLOCK)
		WHERE CreditMemoHeaderId = @CreditMemoHeaderId AND IsActive = 1;

		UPDATE [dbo].[CreditMemo] SET Amount = @FinalAmount,PDFPath = NULL WHERE CreditMemoHeaderId = @CreditMemoHeaderId;

	   SELECT @CreditMemoHeaderId AS CreditMemoHeaderId;

	COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_StandAloneCreditMemoDetails_AddUpdate]'			
			,@ProcedureParameters VARCHAR(3000) = '@CreditMemoHeaderId = ''' + CAST(ISNULL(@CreditMemoHeaderId, '') AS varchar(100))				 
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