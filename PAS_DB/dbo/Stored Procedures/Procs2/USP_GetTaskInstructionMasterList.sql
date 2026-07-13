/***************************************************************  
 ** File:   [USP_GetTaskInstructionMasterList]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to task Instruction Master List
 ** Date:  26-Dec-2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    26-Dec-2024		Devendra Shekh			Created
    2    27-Jan-2025		Ekta Chandegra			Add @IsDeleted parameter
    3    04-Mar-2025		RAJESH GAMI      		Sequence Number logic change (Group by Task)
	4    10-Mar-2025		Divyesh Kathiriya		Update CreatedDate and UpdateDate based on Employee time zone
    5    11-Mar-2025		RAJESH GAMI      		IsDefaultInstruction Added
	6    10-July-2026		Priyansh Patel      	Added the tasks with no instruction also [PN-17039]

	exec dbo.USP_GetTaskInstructionMasterList @MasterCompanyId=1,@IsDeleted=1

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetTaskInstructionMasterList]
	@MasterCompanyId bigint = NULL,
	@IsDeleted BIT,
	@EmployeeId BIGINT
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
    BEGIN TRY
        DECLARE @EmpLegalEntiyId BIGINT = 0;
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

        SELECT @EmpLegalEntiyId = LegalEntityId FROM dbo.Employee WITH (NOLOCK) WHERE EmployeeId = @EmployeeId;

        SELECT
                @CurrntEmpTimeZoneDesc = COALESCE(
                    ETZ.[Description],  -- Prefer Employee's TimeZone description if available
                    LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
                )
            FROM
                dbo.Employee E WITH (NOLOCK)
            LEFT JOIN
                dbo.TimeZone ETZ WITH (NOLOCK)
                ON E.TimeZoneId = ETZ.TimeZoneId
            LEFT JOIN
                dbo.LegalEntity LE WITH (NOLOCK)
                ON E.LegalEntityId = LE.LegalEntityId
            LEFT JOIN
                dbo.TimeZone LTZ WITH (NOLOCK)
                ON LE.TimeZoneId = LTZ.TimeZoneId
            WHERE
                E.EmployeeId = @EmployeeId;

        IF @IsDeleted IS NULL
        BEGIN
            SET @IsDeleted = 0;
        END

        ;WITH CTE AS (
            SELECT
                TIM.TaskInstructionId,
                TIM.ParentId,
                TIM.IsParent,
                T.TaskId,
                T.[Description] TaskName,
                TIM.Title InstructionTitle,
                TIM.SequenceNumber AS SequenceNumber,
                TIM.[Description] InstructionDetails,
                TIM.MasterCompanyId,
                T.CreatedBy,
                T.UpdatedBy,
                CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN
                    CASE WHEN CAST(TIM.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(T.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END
                ELSE (CAST(TIM.CreatedDate AS DATETIME)) END CreatedDate,
                CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN
                    CASE WHEN CAST(TIM.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(T.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END
                ELSE (CAST(TIM.UpdatedDate AS DATETIME)) END UpdatedDate,
                TIM.IsActive,
                TIM.IsDeleted,
                DENSE_RANK() OVER (ORDER BY T.TaskId) AS TaskSrNo,
                ISNULL(TIM.IsDefaultInstruction, 0) IsDefaultInstruction,
                ISNULL(TIM.IsParentInstruction, 0) IsParentInstruction
            FROM dbo.Task T WITH (NOLOCK)
            LEFT JOIN dbo.TaskInstructionMaster TIM WITH (NOLOCK)
                ON TIM.TaskId = T.TaskId
                AND TIM.MasterCompanyId = @MasterCompanyId
                AND ISNULL(TIM.IsActive, 0) = 1
                AND ISNULL(TIM.IsDeleted, 0) = @IsDeleted
            WHERE T.MasterCompanyId = @MasterCompanyId 
              AND ISNULL(T.IsActive, 0) = 1
                AND ISNULL(T.IsDeleted, 0) = @IsDeleted
        )
        SELECT * INTO #LeafTempTbl FROM CTE;
        SELECT * FROM #LeafTempTbl ORDER BY TaskId, SequenceNumber;
		
	END TRY     
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetTaskInstructionMasterList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
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
END