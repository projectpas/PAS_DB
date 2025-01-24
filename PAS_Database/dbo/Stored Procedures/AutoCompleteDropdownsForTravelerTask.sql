/*************************************************************           
 ** File:   [[AutoCompleteDropdownsForTravelerTask]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to search Task
 ** Purpose:         
 ** Date:   21/01/2025              
 ** PARAMETERS:          
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    21/01/2025   Moin Bloch  	Created

    EXEC [dbo].[AutoCompleteDropdownsForTravelerTask] 'Task','TaskId','TaskName','',1,0,'0',1
**************************************************************/
CREATE PROCEDURE [dbo].[AutoCompleteDropdownsForTravelerTask] 
@TableName VARCHAR(50) = NULL, 
@Parameter1 VARCHAR(50) = NULL, 
@Parameter2 VARCHAR(100) = NULL, 
@Parameter3 VARCHAR(50) = NULL, 
@Parameter4 BIT = TRUE, 
@Count VARCHAR(10) = 0, 
@Idlist VARCHAR(MAX) = '0', 
@MasterCompanyId INT
AS BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    BEGIN TRY
		DECLARE @TotalRecord int = 0;   
		DECLARE @MinId BIGINT = 1;    

		
		IF OBJECT_ID(N'tempdb..#TempTravelerTasktbl') IS NOT NULL
		BEGIN
			DROP TABLE #TempTravelerTasktbl
		END

		IF OBJECT_ID(N'tempdb..#TempTravelerTasktblMain') IS NOT NULL
		BEGIN
			DROP TABLE #TempTravelerTasktblMain
		END
			
		CREATE TABLE #TempTravelerTasktbl(
			[ID] BIGINT NOT NULL IDENTITY, 
			[Value] BIGINT NULL,
			[Label] VARCHAR(200),
			[SequenceNumber] INT NULL
		)
		CREATE TABLE #TempTravelerTasktblMain(
			[ID] BIGINT NOT NULL IDENTITY, 
			[Value] BIGINT NULL,
			[Label] VARCHAR(200),
			[SequenceNumber] INT NULL
		)

		IF(@Count='0')
		BEGIN      		
			IF(@TableName='Task')
			BEGIN
				IF(@Parameter4 = 1)
				BEGIN 
					INSERT INTO #TempTravelerTasktbl ([Value],[Label],[SequenceNumber])		
						 SELECT DISTINCT [WorkOrderTaskId] AS [Value], 
						                 [TaskName] AS [Label], 
										 [SequenceNumber] AS [Sequence] 
										 --1 AS [IsTravelerTask],
										 --0 AS [StandardHours], 
										 --0 AS [StandardMinute]
						 FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId] = @MasterCompanyId 						 
						   AND ([IsActive] = 1 AND [IsDeleted] = 0 AND(TaskName LIKE '%'+ @Parameter3 +'%'))

                         UNION

                         SELECT DISTINCT [WorkOrderTaskId] AS [Value], 
						                 [TaskName] AS [Label], 
										 [SequenceNumber] AS [Sequence]--,
										 --1 AS [IsTravelerTask], 
										 --0 AS [StandardHours], 
										 --0 AS [StandardMinute]
                         FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId] = @MasterCompanyId 
						   AND [TaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
                        
						 UNION

                         SELECT DISTINCT [TaskId] AS [Value],
						                 [Description] AS [Label],
										 [Sequence]--, 
										 --[IsTravelerTask], 
										 --[StandardHours], 
										 --[StandardMinute]
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE [MasterCompanyId]=@MasterCompanyId 
						 AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND([Description] LIKE '%'+@Parameter3+'%'))

                         UNION

                         SELECT DISTINCT [TaskId] AS [Value],
										 [Description] AS [Label],
										 [Sequence]--,
										 --[IsTravelerTask],
										 --[StandardHours],
										 --[StandardMinute]
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE MasterCompanyId=@MasterCompanyId AND TaskId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] asc
                  
                END
                ELSE 
				BEGIN      
						INSERT INTO #TempTravelerTasktbl ([Value],[Label],[SequenceNumber])		
						SELECT DISTINCT [WorkOrderTaskId] AS [Value],
						                 [TaskName] AS [Label],
										 [SequenceNumber] AS [Sequence]--,
										 --0 AS [IsTravelerTask],
										 --0 AS [StandardHours],
										 --0 AS [StandardMinute]
                          FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId]=@MasterCompanyId 						 
						   AND [IsActive]=1 AND [IsDeleted]=0 AND [TaskName] LIKE '%'+@Parameter3+'%'
                         
						 UNION
                         
						 SELECT DISTINCT [WorkOrderTaskId] AS [Value],
						                 [TaskName] AS [Label],
										 [SequenceNumber] AS [Sequence]--,
										 --0 AS [IsTravelerTask],
										 --0 AS [StandardHours],
										 --0 AS [StandardMinute]
                         FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId]=@MasterCompanyId 						  
						   AND [WorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))

						  UNION

						  SELECT DISTINCT [TaskId] AS [Value],
						                  [Description] AS [Label],
										  [Sequence]--, 
										  --[IsTravelerTask],
										  --[StandardHours],
										  --[StandardMinute]
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE [MasterCompanyId]=@MasterCompanyId 
						   AND [IsActive]=1 AND ISNULL(IsDeleted, 0)=0 
						   AND [Description] LIKE '%'+@Parameter3+'%'
                         
						 UNION

                         SELECT DISTINCT [TaskId] AS [Value],
						                 [Description] AS [Label],
										 [Sequence]--,
										 --[IsTravelerTask],
										 --[StandardHours],
										 --[StandardMinute]
                         FROM dbo.Task WITH(NOLOCK)
                         WHERE [MasterCompanyId] = @MasterCompanyId 
						 AND [TaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )                      
                         ORDER BY [Sequence] asc
                END
            END           
        END

		SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #TempTravelerTasktbl    

		WHILE @MinId <= @TotalRecord
		BEGIN
			DECLARE @Label VARCHAR(200)='';
			SELECT @Label = [Label] FROM #TempTravelerTasktbl WHERE [ID] = @MinId
			
			IF NOT EXISTS(SELECT 1 FROM #TempTravelerTasktblMain WHERE [Label]=@Label) 
			BEGIN
				INSERT INTO #TempTravelerTasktblMain ([Value],[Label],[SequenceNumber])
				SELECT [Value],[Label],[SequenceNumber] FROM #TempTravelerTasktbl WHERE [ID] = @MinId
			END						
			SET @MinId = @MinId + 1
		END       
        
		SELECT [Value],[Label],[SequenceNumber] FROM #TempTravelerTasktblMain

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) =db_name(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments VARCHAR(150) ='AutoCompleteDropdowns', @ProcedureParameters VARCHAR(3000) = 
			'@Parameter1 = '''+CAST(ISNULL(@TableName, '') as varchar(100))+ 
			'@Parameter2 = '''+CAST(ISNULL(@Parameter1, '') as varchar(100))+
			'@Parameter3 = '''+CAST(ISNULL(@Parameter2, '') as varchar(100))+
			'@Parameter4 = '''+CAST(ISNULL(@Parameter3, '') as varchar(100))+
			'@Parameter5 = '''+CAST(ISNULL(@Parameter4, '') as varchar(100))+
			'@Parameter6 = '''+CAST(ISNULL(@Count, '') as varchar(100))+
			'@Parameter7 = '''+CAST(ISNULL(@Idlist, '') as varchar(100))+
			'@Parameter8 = '''+CAST(ISNULL(@MasterCompanyId, '') as varchar(100)), 
			@ApplicationName VARCHAR(100) = 'PAS'
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
        EXEC spLogException @DatabaseName=@DatabaseName, @AdhocComments=@AdhocComments, @ProcedureParameters=@ProcedureParameters, @ApplicationName=@ApplicationName, @ErrorLogID=@ErrorLogID OUTPUT;
        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END