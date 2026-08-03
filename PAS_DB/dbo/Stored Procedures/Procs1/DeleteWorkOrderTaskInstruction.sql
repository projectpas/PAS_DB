/*************************************************************             
** File:   [DeleteWorkOrderTaskInstruction]
** Author:   Vishal Suthar
** Description: This procedre is used to delete work order task instruction
** Purpose:
** Date:   01/13/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   01/13/2025   Vishal Suthar		Created
	2   03/21/2025   Ekta Chandegra		Add dbo.USP_AddWorkOrderTaskHistory call to add history
	3   03/24/2025   Ekta Chandegra		Update IsDeleted value of deleted Work Order Task Instruction in WorkOrderTaskHistory 
	4   04/29/2025   Ekta Chandegra		Rearrange sequence of remaining instructions after delete
    5   08/01/2025   SUMIT KUMAR		[PN-17518] Supplied IsFromWorkFlow to USP_InsertWorkOrderTaskInstructionHistory as 0 as it was missing and throughing error

EXEC [DeleteWorkOrderTaskInstruction] 3
**************************************************************/
CREATE   PROCEDURE [dbo].[DeleteWorkOrderTaskInstruction]
	@WorkOrderTaskInstructionId BIGINT,
	@CreatedBy VARCHAR(256),
	@WorkOrderTaskId BIGINT,
	@InstructionListId VARCHAR(250)

AS
	BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		EXEC dbo.USP_AddWorkOrderTaskHistory @WorkOrderTaskId,@CreatedBy,@WorkOrderTaskInstructionId,NULL

		   -- STEP 2: Recursive delete
        ;WITH RecursiveDelete AS (
            SELECT WorkOrderTaskInstructionId
            FROM dbo.WorkOrderTaskInstruction WITH (NOLOCK)
            WHERE WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId

            UNION ALL

            SELECT child.WorkOrderTaskInstructionId
            FROM dbo.WorkOrderTaskInstruction child WITH (NOLOCK)
            INNER JOIN RecursiveDelete parent 
                ON child.ParentId = parent.WorkOrderTaskInstructionId
        )

		-- Delete all identified records
		DELETE FROM DBO.WorkOrderTaskInstruction
		WHERE WorkOrderTaskInstructionId IN (SELECT WorkOrderTaskInstructionId FROM RecursiveDelete);

		 -- STEP 3: Mark deleted in SubWorkOrderTaskHistory
        UPDATE dbo.WorkOrderTaskHistory
        SET IsDeleted = 1
        WHERE WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId;

		 -- STEP 4: Re-sequence remaining instructions
        ;WITH PreSequence AS (
            SELECT 
                WorkOrderTaskInstructionId,
                ParentId,
                ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY WorkOrderTaskInstructionId) AS NewSequence
            FROM dbo.WorkOrderTaskInstruction WITH(NOLOCK)
            WHERE WorkOrderTaskId = @WorkOrderTaskId
        )
        , Hierarchy AS (
            -- Anchor: top-level
            SELECT 
                s.WorkOrderTaskInstructionId,
                s.ParentId,
                s.NewSequence,
                CAST(s.NewSequence AS VARCHAR(MAX)) AS ParentSequenceNumber
            FROM PreSequence s
            WHERE s.ParentId IS NULL

            UNION ALL

            -- Recursion: children
            SELECT 
                s.WorkOrderTaskInstructionId,
                s.ParentId,
                s.NewSequence,
                CAST(p.ParentSequenceNumber + '.' + CAST(s.NewSequence AS VARCHAR) AS VARCHAR(MAX))
            FROM PreSequence s
            INNER JOIN Hierarchy p ON s.ParentId = p.WorkOrderTaskInstructionId
        )

		UPDATE WOTI
        SET 
            WOTI.SequenceNumber = H.NewSequence,
            WOTI.ParentSequenceNumber = H.ParentSequenceNumber,
            WOTI.UpdatedBy = @CreatedBy,
            WOTI.UpdatedDate = GETUTCDATE()
        FROM dbo.WorkOrderTaskInstruction WOTI
        INNER JOIN Hierarchy H ON WOTI.WorkOrderTaskInstructionId = H.WorkOrderTaskInstructionId;

		 -- STEP 5: Log instruction update history for all remaining instructions
        DECLARE @UpdatedInstructionId BIGINT;
        DECLARE UpdatedCursor CURSOR FOR
        SELECT WorkOrderTaskInstructionId
        FROM dbo.WorkOrderTaskInstruction WITH(NOLOCK)
        WHERE WorkOrderTaskId = @WorkOrderTaskId;

        OPEN UpdatedCursor;
        FETCH NEXT FROM UpdatedCursor INTO @UpdatedInstructionId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.USP_InsertWorkOrderTaskInstructionHistory 
                @UpdatedInstructionId, @CreatedBy, @InstructionListId, NULL, 0;

			EXEC dbo.USP_AddWorkOrderTaskHistory 
                @WorkOrderTaskId, @CreatedBy, @UpdatedInstructionId, NULL;

            FETCH NEXT FROM UpdatedCursor INTO @UpdatedInstructionId;
        END

        CLOSE UpdatedCursor;
        DEALLOCATE UpdatedCursor;


        COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteWorkOrderTaskInstruction' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderTaskInstructionId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END