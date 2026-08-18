/***************************************************************
 ** File:        [USP_GetTaskInstructionMasterHistoryByTaskId]
 ** Description: Returns parent and child instruction audit history for a task.
 ** Date:        06-Aug-2026

 **********************             
  ** Change History             
 **********************             
 ** S NO		Date			Author				Change Description              
 ** --		--------		-------------		--------------------------------            
    1		06/08/2026  	Nakul Chandigra			Created  

 EXEC dbo.USP_GetTaskInstructionMasterHistoryByTaskId @TaskId = 119, @EmployeeId = 1
***************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetTaskInstructionMasterHistoryByTaskId]
    @TaskId BIGINT,
    @EmployeeId BIGINT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

        SELECT
            @CurrntEmpTimeZoneDesc = COALESCE(
                ETZ.[Description],
                LTZ.[Description]
            )
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK)
            ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK)
            ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK)
            ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

        ;WITH DeduplicatedHistory AS
        (
            SELECT
                A.*,
                ROW_NUMBER() OVER
                (
                    PARTITION BY
                        A.TaskInstructionId,
                        HASHBYTES
                        (
                            'SHA2_256',
                            CONCAT(
                                ISNULL(A.Title, ''), CHAR(31),
                                ISNULL(A.[Description], ''), CHAR(31),
                                A.TaskId, CHAR(31),
                                ISNULL(A.SequenceNumber, -1), CHAR(31),
                                ISNULL(A.ParentId, 0), CHAR(31),
                                ISNULL(A.IsParent, 0), CHAR(31),
                                A.MasterCompanyId, CHAR(31),
                                A.CreatedBy, CHAR(31),
                                A.UpdatedBy, CHAR(31),
                                CONVERT(VARCHAR(33), A.CreatedDate, 126), CHAR(31),
                                CONVERT(VARCHAR(33), A.UpdatedDate, 126), CHAR(31),
                                A.IsActive, CHAR(31),
                                A.IsDeleted, CHAR(31),
                                ISNULL(A.IsDefaultInstruction, 0), CHAR(31),
                                ISNULL(A.IsParentInstruction, 0)
                            )
                        )
                    ORDER BY A.TaskInstructionAuditId DESC
                ) AS DuplicateRowNumber
            FROM dbo.TaskInstructionMasterAudit A WITH (NOLOCK)
            WHERE A.TaskId = @TaskId
        )
        SELECT
            A.TaskInstructionAuditId,
            A.TaskInstructionId,
            ISNULL(A.IsDefaultInstruction, 0) AS IsDefaultInstruction,
            A.Title,
            A.[Description],

            CASE
                WHEN ISNULL(A.IsParentInstruction, 0) = 1
                    THEN 'Parent'
                ELSE CONCAT(
                    'Child of: ',
                    COALESCE(ParentAudit.Title, ParentMaster.Title, '-')
                )
            END AS ParentHierarchy,

            A.ParentId,
            ISNULL(A.IsParentInstruction, 0) AS IsParentInstruction,
            A.SequenceNumber,

            CASE
                WHEN ISNULL(A.IsParentInstruction, 0) = 1
                     OR ISNULL(
                            ParentAudit.SequenceNumber,
                            ParentMaster.SequenceNumber
                        ) IS NULL
                     OR ISNULL(
                            ParentAudit.SequenceNumber,
                            ParentMaster.SequenceNumber
                        ) = 0
                    THEN CAST(A.SequenceNumber AS VARCHAR(50))
                ELSE CONCAT(
                    ISNULL(
                        ParentAudit.SequenceNumber,
                        ParentMaster.SequenceNumber
                    ),
                    '.',
                    A.SequenceNumber
                )
            END AS SequenceToDisplay,

            T.[Description] AS TaskName,
            A.CreatedBy,

            CASE
                WHEN @EmployeeId <> 0
                     AND ISNULL(@CurrntEmpTimeZoneDesc, '') <> ''
                    THEN CAST(
                        dbo.ConvertUTCtoLocal(
                            A.CreatedDate,
                            @CurrntEmpTimeZoneDesc
                        ) AS DATETIME
                    )
                ELSE CAST(A.CreatedDate AS DATETIME)
            END AS CreatedDate,

            A.UpdatedBy,

            CASE
                WHEN @EmployeeId <> 0
                     AND ISNULL(@CurrntEmpTimeZoneDesc, '') <> ''
                    THEN CAST(
                        dbo.ConvertUTCtoLocal(
                            A.UpdatedDate,
                            @CurrntEmpTimeZoneDesc
                        ) AS DATETIME
                    )
                ELSE CAST(A.UpdatedDate AS DATETIME)
            END AS UpdatedDate,

            ISNULL(A.IsDeleted, 0) AS IsDeleted

        FROM DeduplicatedHistory A
        INNER JOIN dbo.Task T WITH (NOLOCK)
            ON T.TaskId = A.TaskId

        OUTER APPLY
        (
            SELECT TOP 1
                PA.Title,
                PA.SequenceNumber
            FROM dbo.TaskInstructionMasterAudit PA WITH (NOLOCK)
            WHERE PA.TaskInstructionId = A.ParentId
              AND PA.TaskInstructionAuditId
                    <= A.TaskInstructionAuditId
            ORDER BY PA.TaskInstructionAuditId DESC
        ) ParentAudit

        LEFT JOIN dbo.TaskInstructionMaster ParentMaster WITH (NOLOCK)
            ON ParentMaster.TaskInstructionId = A.ParentId

        WHERE A.DuplicateRowNumber = 1
          AND NOT
          (
              ISNULL(A.SequenceNumber, 0) = 0
              AND ISNULL(A.IsParentInstruction, 0) = 0
          )

        ORDER BY
            A.UpdatedDate DESC,
            A.TaskInstructionAuditId DESC;

    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150)
                = 'USP_GetTaskInstructionMasterHistoryByTaskId',
            @ProcedureParameters VARCHAR(3000)
                = '@TaskId = '''
                    + ISNULL(CAST(@TaskId AS VARCHAR(100)), '')
                    + ''', @EmployeeId = '''
                    + ISNULL(CAST(@EmployeeId AS VARCHAR(100)), '')
                    + '''',
            @ApplicationName VARCHAR(100) = 'PAS';

        EXEC dbo.spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR
        (
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16,
            1,
            @ErrorLogID
        );

        RETURN (1);
    END CATCH
END;