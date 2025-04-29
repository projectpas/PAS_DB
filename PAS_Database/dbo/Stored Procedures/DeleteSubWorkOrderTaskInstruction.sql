/*************************************************************             
** File:   [DeleteSubWorkOrderTaskInstruction]
** Author:   Vishal Suthar
** Description: This procedre is used to delete sub work order task instruction
** Purpose:
** Date:   03/21/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   03/21/2025   Vishal Suthar		Created
	2   03/28/2025   Ekta Chandegra		Add Sub Work Order Task History
	3   04/29/2025   Ekta Chandegra		Rearrange sequence of remaining instructions after delete

EXEC [DeleteSubWorkOrderTaskInstruction] 3
**************************************************************/
CREATE   PROCEDURE [dbo].[DeleteSubWorkOrderTaskInstruction]
    @SubWorkOrderTaskInstructionId BIGINT,
    @CreatedBy VARCHAR(256),
    @SubWorkOrderTaskId BIGINT,
	@InstructionListId VARCHAR(250)
AS
BEGIN
    BEGIN TRY
        -- Start transaction
        BEGIN TRANSACTION;

        -- Log history before deletion
        EXEC dbo.USP_AddSubWorkOrderTaskHistory @SubWorkOrderTaskId, @CreatedBy, @SubWorkOrderTaskInstructionId, NULL;

          -- STEP 2: Recursive delete
        ;WITH RecursiveDelete AS (
            SELECT SubWorkOrderTaskInstructionId
            FROM dbo.SubWorkOrderTaskInstruction WITH (NOLOCK)
            WHERE SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId

            UNION ALL

            SELECT child.SubWorkOrderTaskInstructionId
            FROM dbo.SubWorkOrderTaskInstruction child WITH (NOLOCK)
            INNER JOIN RecursiveDelete parent 
                ON child.ParentId = parent.SubWorkOrderTaskInstructionId
        )
        DELETE FROM dbo.SubWorkOrderTaskInstruction
        WHERE SubWorkOrderTaskInstructionId IN (SELECT SubWorkOrderTaskInstructionId FROM RecursiveDelete);

        -- STEP 3: Mark deleted in SubWorkOrderTaskHistory
        UPDATE dbo.SubWorkOrderTaskHistory
        SET IsDeleted = 1
        WHERE SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId;

        -- STEP 4: Re-sequence remaining instructions
        ;WITH PreSequence AS (
            SELECT 
                SubWorkOrderTaskInstructionId,
                ParentId,
                ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY SubWorkOrderTaskInstructionId) AS NewSequence
            FROM dbo.SubWorkOrderTaskInstruction
            WHERE SubWorkOrderTaskId = @SubWorkOrderTaskId
        )
        , Hierarchy AS (
            -- Anchor: top-level
            SELECT 
                s.SubWorkOrderTaskInstructionId,
                s.ParentId,
                s.NewSequence,
                CAST(s.NewSequence AS VARCHAR(MAX)) AS ParentSequenceNumber
            FROM PreSequence s
            WHERE s.ParentId IS NULL

            UNION ALL

            -- Recursion: children
            SELECT 
                s.SubWorkOrderTaskInstructionId,
                s.ParentId,
                s.NewSequence,
                CAST(p.ParentSequenceNumber + '.' + CAST(s.NewSequence AS VARCHAR) AS VARCHAR(MAX))
            FROM PreSequence s
            INNER JOIN Hierarchy p ON s.ParentId = p.SubWorkOrderTaskInstructionId
        )
        UPDATE SWOTI
        SET 
            SWOTI.SequenceNumber = H.NewSequence,
            SWOTI.ParentSequenceNumber = H.ParentSequenceNumber,
            SWOTI.UpdatedBy = @CreatedBy,
            SWOTI.UpdatedDate = GETUTCDATE()
        FROM dbo.SubWorkOrderTaskInstruction SWOTI
        INNER JOIN Hierarchy H ON SWOTI.SubWorkOrderTaskInstructionId = H.SubWorkOrderTaskInstructionId;

        -- STEP 5: Log instruction update history for all remaining instructions
        DECLARE @UpdatedInstructionId BIGINT;
        DECLARE UpdatedCursor CURSOR FOR
        SELECT SubWorkOrderTaskInstructionId
        FROM dbo.SubWorkOrderTaskInstruction
        WHERE SubWorkOrderTaskId = @SubWorkOrderTaskId;

        OPEN UpdatedCursor;
        FETCH NEXT FROM UpdatedCursor INTO @UpdatedInstructionId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.USP_InsertSubWorkOrderTaskInstructionHistory 
                @UpdatedInstructionId, @CreatedBy, @InstructionListId, NULL;

			EXEC dbo.USP_AddSubWorkOrderTaskHistory 
                @SubWorkOrderTaskId, @CreatedBy, @UpdatedInstructionId, NULL;

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
              , @AdhocComments     VARCHAR(150)    = 'DeleteSubWorkOrderTaskInstruction' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderTaskInstructionId, '') + ''
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