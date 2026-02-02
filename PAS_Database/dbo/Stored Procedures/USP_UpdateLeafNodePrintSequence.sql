/*************************************************************           
 ** File:   [USP_GetPrintSequenceLeafData]      
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used Update Sequence 
 ** Purpose:         
 ** Date:   21/01/2026     
         
 ** PARAMETERS:    @RountingStructureId   bigint     
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    21/01/2026  Bhargav Saliya     Created

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateLeafNodePrintSequence]
	@tbl_sequenceDataType [LeafNodeSequenceType] READONLY
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		DECLARE @rowCount INT, @currentRow INT;
		DECLARE @LeafNodeId bigint,
				@Name varchar(256),
				@PrintSequenceNumber int,
				@MasterCompanyId int,
				@ReportingStructureId bigint;

		IF OBJECT_ID('tempdb..#LeafNodePrintSequence') IS NOT NULL
			DROP TABLE #LeafNodePrintSequence

		CREATE TABLE #LeafNodePrintSequence
		(
			[RecordId] [bigint] IDENTITY(1,1) NOT NULL,
			[LeafNodeId] [bigint] NULL,
			[Name] [varchar](256) NULL,
			[PrintSequenceNumber] [int] NULL,
			[MasterCompanyId] [int] NULL,
			[ReportingStructureId] [bigint] NULL
		);

		INSERT INTO #LeafNodePrintSequence
			([LeafNodeId], [Name], [PrintSequenceNumber], [MasterCompanyId], [ReportingStructureId])
			SELECT	[LeafNodeId], [Name], [PrintSequenceNumber], [MasterCompanyId], [ReportingStructureId]
			FROM @tbl_sequenceDataType

		SELECT @rowCount = MAX(RecordId), @currentRow = MIN(RecordId) FROM #LeafNodePrintSequence;
		WHILE @currentRow <= @rowCount
		BEGIN
				SELECT
					@LeafNodeId = LeafNodeId,
					@Name = [Name],
					@PrintSequenceNumber = [PrintSequenceNumber],
					@MasterCompanyId = [MasterCompanyId],
					@ReportingStructureId = [ReportingStructureId]
				FROM #LeafNodePrintSequence
				WHERE [RecordId] = @currentRow;

				UPDATE [dbo].[LeafNode]
				SET	[PrintSequenceNumber] = CASE WHEN @PrintSequenceNumber IS NULL OR LTRIM(RTRIM(@PrintSequenceNumber)) = '' THEN [PrintSequenceNumber] ELSE @PrintSequenceNumber END
				WHERE [MasterCompanyId] = @MasterCompanyId AND
					  [ReportingStructureId] = @ReportingStructureId AND
					  [LeafNodeId] = @LeafNodeId;

			SET @currentRow = @currentRow + 1;
		END

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_UpdateLeafNodePrintSequence'
			,@ProcedureParameters VARCHAR(3000) =
					'@Parameter1 = ''' + ''', '
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)
		RETURN (1);           
	END CATCH
END;