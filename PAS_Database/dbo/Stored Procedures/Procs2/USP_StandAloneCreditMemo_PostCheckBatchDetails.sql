/*************************************************************           
 ** File:   [USP_StandAloneCreditMemo_PostCheckBatchDetails]           
 ** Author:  AMIT GHEDIYA
 ** Description: This stored procedure is used to post into batch details
 ** Purpose:         
 ** Date:   13/09/2023      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date           Author					Change Description            
 ** --   --------       -------				   --------------------------------          
    1    13/09/2023     AMIT GHEDIYA			Created
	2	 09/15/2023     AMIT GHEDIYA	        Update for management stucture add in common table.
	3	 09/18/2023     AMIT GHEDIYA	        Update status to Approved after post batch.
    4    10/16/2023      Moin Bloch		        Modify(Added Posted Status Insted of Closed Credit Memo Status)

-- EXEC USP_StandAloneCreditMemo_PostCheckBatchDetails 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_StandAloneCreditMemo_PostCheckBatchDetails]
@CreditMemoHeaderId BIGINT=NULL,
@Result BIGINT OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY 
		BEGIN TRANSACTION
		BEGIN
			
			DECLARE @StatusId INT,@StatusName VARCHAR(50),@StandAloneCreditMemoDetailsId BIGINT,
				    @ManagementStructureId BIGINT,@Amount DECIMAL(18,2),@StandAloneCreditMemoDetailId BIGINT,
				    @MasterCompanyId INT,@UpdatedBy VARCHAR(50),@MasterLoopID INT;

			SELECT @StatusId = Id, @StatusName = Name FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE Name = 'Posted';
			
			IF OBJECT_ID(N'tempdb..#tmpStandAloneCreditMemoDetails') IS NOT NULL
			BEGIN
				DROP TABLE #tmpStandAloneCreditMemoDetails
			END

			CREATE TABLE #tmpStandAloneCreditMemoDetails
			(
				[ID] INT IDENTITY,
				[StandAloneCreditMemoDetailId] BIGINT NULL,
				[Amount] [decimal](18, 2) NOT NULL,
				[ManagementStructureId] [bigint] NULL,
				[MasterCompanyId] [int],
				[UpdatedBy] [varchar](50)
			)

			INSERT INTO #tmpStandAloneCreditMemoDetails ([StandAloneCreditMemoDetailId],[Amount],
													 [ManagementStructureId],[MasterCompanyId],[UpdatedBy])
			SELECT [StandAloneCreditMemoDetailId],[Amount], 
													[ManagementStructureId],[MasterCompanyId],[UpdatedBy]
					FROM StandAloneCreditMemoDetails 
			WHERE CreditMemoHeaderId = @CreditMemoHeaderId AND IsActive = 1 AND IsDeleted = 0;

			SELECT  @MasterLoopID = MAX(ID) FROM #tmpStandAloneCreditMemoDetails;

			WHILE(@MasterLoopID > 0)
			BEGIN
				--Select Item that ready for post
				SELECT @StandAloneCreditMemoDetailId = [StandAloneCreditMemoDetailId],
					   @Amount = ABS([Amount]),
					   @ManagementStructureId = ManagementStructureId,
					   @MasterCompanyId = MasterCompanyId,
					   @UpdatedBy = UpdatedBy
				FROM #tmpStandAloneCreditMemoDetails WHERE [ID] = @MasterLoopID;
				
				-- Add in batch details
				EXEC [dbo].[USP_StandAloneCM_PostCheckBatchDetails] @StandAloneCreditMemoDetailId,@CreditMemoHeaderId,@ManagementStructureId,@Amount,@MasterCompanyId,@UpdatedBy;

				SET @MasterLoopID = @MasterLoopID - 1;
			END

			--Update status to Approved after all postbatch.
			UPDATE [dbo].[CreditMemo] 
			   SET [StatusId] = @StatusId, 
			       [Status] = @StatusName , 
				   [InvoiceDate] = GETUTCDATE()  
			 WHERE [CreditMemoHeaderId] = @CreditMemoHeaderId;
			
			SELECT	@Result = @CreditMemoHeaderId;
		END
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_StandAloneCreditMemo_PostCheckBatchDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CreditMemoHeaderId, '') AS varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END