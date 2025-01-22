/*************************************************************           
 ** File:   [AutoCompleteDropdownsForTask]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to search Task
 ** Purpose:         
 ** Date:   09/01/2025              
 ** PARAMETERS:          
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/01/2025   Moin Bloch  	Cretaed

    EXEC AutoCompleteDropdownsForTask 'Task','TaskId','Description','',1,0,'0',1,4740,4305 
	EXEC AutoCompleteDropdownsForTask 'WorkOrderTask','TaskId','TaskName','',1,0,'11',1,4739,4304 
	exec dbo.AutoCompleteDropdownsForTask @TableName=N'WorkOrderTask',@Parameter1=N'TaskId',@Parameter2=N'TaskName',@Parameter3=N'',@Parameter4=1,@Count=0,@Idlist=N'0',@MasterCompanyId=1,@WorkOrderId=4742,@WorkOrderPartNumberId=606,@IsSubWorkOrder=0
**************************************************************/
CREATE PROCEDURE [dbo].[AutoCompleteDropdownsForTask] 
@TableName VARCHAR(50) = NULL, 
@Parameter1 VARCHAR(50) = NULL, 
@Parameter2 VARCHAR(100) = NULL, 
@Parameter3 VARCHAR(50) = NULL, 
@Parameter4 BIT = TRUE, 
@Count VARCHAR(10) = 0, 
@Idlist VARCHAR(MAX) = '0', 
@MasterCompanyId INT,
@WorkOrderId BIGINT,
@WorkOrderPartNumberId BIGINT,
@IsSubWorkOrder BIT 
AS BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    BEGIN TRY
        DECLARE @Sql NVARCHAR(MAX);     

		IF(@IsSubWorkOrder = 1)
		BEGIN
			SELECT @WorkOrderId=[WorkOrderId],@WorkOrderPartNumberId=[WorkOrderPartNumberId] FROM dbo.[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @WorkOrderId;
		END			
		IF(@Count='0')
		BEGIN      		
			IF(@TableName='WorkOrderTask')
			BEGIN
				IF(@Parameter4 = 1)
				BEGIN                      
						 SELECT DISTINCT [WorkOrderTaskId] AS [Value], 
						                 [TaskName] AS [Label], 
										 [SequenceNumber] AS [Sequence], 
										 1 AS [IsTravelerTask],
										 0 AS [StandardHours], 
										 0 AS [StandardMinute]
						 FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId] = @MasterCompanyId 
						   AND [WorkOrderId] = @WorkOrderId 
						   AND [WorkOrderPartNumberId] = @WorkOrderPartNumberId
						   AND ([IsActive] = 1 AND [IsDeleted] = 0 AND(TaskName LIKE '%'+ @Parameter3 +'%'))

                         UNION

                         SELECT DISTINCT [WorkOrderTaskId] AS [Value], 
						                 [TaskName] AS [Label], 
										 [SequenceNumber] AS [Sequence],
										 1 AS [IsTravelerTask], 
										 0 AS [StandardHours], 
										 0 AS [StandardMinute]
                         FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId] = @MasterCompanyId 
						   AND [WorkOrderId] = @WorkOrderId 
						   AND [WorkOrderPartNumberId] = @WorkOrderPartNumberId
						   AND [TaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] asc
                 END
                 ELSE 
				 BEGIN                        
						 SELECT DISTINCT [WorkOrderTaskId] AS [Value],
						                 [TaskName] AS [Label],
										 [SequenceNumber] AS [Sequence],
										 0 AS [IsTravelerTask],
										 0 AS [StandardHours],
										 0 AS [StandardMinute]
                         FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId]=@MasterCompanyId 
						   AND [WorkOrderId] = @WorkOrderId 
						   AND [WorkOrderPartNumberId] = @WorkOrderPartNumberId
						   AND [IsActive]=1 AND [IsDeleted]=0 AND [TaskName] LIKE '%'+@Parameter3+'%'
                         
						 UNION
                         
						 SELECT DISTINCT [WorkOrderTaskId] AS [Value],
						                 [TaskName] AS [Label],
										 [SequenceNumber] AS [Sequence],
										 0 AS [IsTravelerTask],
										 0 AS [StandardHours],
										 0 AS [StandardMinute]
                         FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId]=@MasterCompanyId 
						   AND [WorkOrderId] = @WorkOrderId 
						   AND [WorkOrderPartNumberId] = @WorkOrderPartNumberId
						   AND [WorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] asc
                 END
            END           
        END
        ELSE 
		BEGIN
            IF(@TableName='WorkOrderTask')
			BEGIN
				IF(@Parameter4 = 1)
				BEGIN
					--print 111
					SELECT DISTINCT [WorkOrderTaskId] AS [Value], 
					                [TaskName] AS [Label], 
									[SequenceNumber] AS [Sequence],
									1 [IsTravelerTask], 
									0 AS [StandardHours],
									0 AS [StandardMinute],
									'' AS [Descrepancy],
								    '' AS [Resolution]
                    FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                    WHERE [MasterCompanyId]=@MasterCompanyId 					
					  AND [WorkOrderId] = @WorkOrderId 
				      AND [WorkOrderPartNumberId] = @WorkOrderPartNumberId 
					  AND ([IsActive]=1 AND [IsDeleted]=0 AND ([TaskName] LIKE '%'+@Parameter3+'%'))
                    
					UNION
                    
					SELECT DISTINCT [WorkOrderTaskId] AS [Value], 
					                [TaskName] AS [Label], 
									[SequenceNumber] AS [Sequence], 
									1 AS [IsTravelerTask], 
									0 AS [StandardHours],
									0 AS [StandardMinute],
									'' AS [Descrepancy],
									'' AS [Resolution]
                    FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                    WHERE [MasterCompanyId] = @MasterCompanyId 
					  AND [WorkOrderId] = @WorkOrderId 
				      AND [WorkOrderPartNumberId] = @WorkOrderPartNumberId 
					  AND [WorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                      ORDER BY [Sequence] ASC
                END
                ELSE
				BEGIN
						 SELECT DISTINCT [WorkOrderTaskId] AS [Value], 
						                 [TaskName] AS [Label], 
										 [SequenceNumber] AS [Sequence], 
										 1 AS [IsTravelerTask], 
										 0 AS [StandardHours],
										 0 AS [StandardMinute],
										 '' AS [Descrepancy],
										 '' AS [Resolution]
                         FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId]=@MasterCompanyId 
						 AND [WorkOrderId] = @WorkOrderId 
				         AND [WorkOrderPartNumberId] = @WorkOrderPartNumberId 
						 AND [IsActive]=1 AND [IsDeleted]=0 AND [TaskName] LIKE '%'+@Parameter3+'%'
                         
						 UNION
                         
						 SELECT DISTINCT [WorkOrderTaskId] AS [Value], 
						                 [TaskName] AS [Label], 
										 [SequenceNumber] AS [Sequence],
										 1 AS [IsTravelerTask], 
										 0 AS [StandardHours],
										 0 AS [StandardMinute],
										 '' AS [Descrepancy],
										 '' AS [Resolution]
                         FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
                         WHERE [MasterCompanyId] = @MasterCompanyId 
						 AND [WorkOrderId] = @WorkOrderId 
				         AND [WorkOrderPartNumberId] = @WorkOrderPartNumberId 
					     AND [WorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] asc
                END
            END            
        END
		
        EXEC sp_executesql @Sql;

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