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
    1    09/01/2025   Moin Bloch  		Cretaed
	2    28/01/2025   Moin Bloch  		Added field IsTravelerTask, StandardHours, StandardMinute for Task Table 
	3    01/04/2025   Devendra Shekh	Modified (Order By [TaskName] ASC)
	4    28/04/2025   Moin Bloch	    Modified (Order By [Sequence] ASC)

    EXEC AutoCompleteDropdownsForTask 'Task','TaskId','Description','',1,0,'0',1,4740,4305 
	EXEC AutoCompleteDropdownsForTask 'WorkOrderTask','TaskId','TaskName','',1,0,'11',1,4739,4304 
	exec dbo.AutoCompleteDropdownsForTask @TableName=N'WorkOrderTask',@Parameter1=N'TaskId',@Parameter2=N'TaskName',@Parameter3=N'',@Parameter4=1,@Count=0,@Idlist=N'0',@MasterCompanyId=1,@WorkOrderId=4742,@WorkOrderPartNumberId=606,@IsSubWorkOrder=0
**************************************************************/
CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsForTask] 
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
			SELECT @WorkOrderId = [WorkOrderId], @WorkOrderPartNumberId = [WorkOrderPartNumberId] FROM dbo.[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @WorkOrderId;
		END

		IF (@Count='0')
		BEGIN      		
			IF(@TableName='WorkOrderTask')
			BEGIN
				IF(@Parameter4 = 1)
				BEGIN                      
					SELECT DISTINCT WOT.[WorkOrderTaskId] AS [Value], 
									WOT.[TaskName] AS [Label], 
									WOT.[SequenceNumber] AS [Sequence], 										
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
									CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute]
					FROM [dbo].[WorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
					WHERE WOT.[MasterCompanyId] = @MasterCompanyId 
					AND WOT.[WorkOrderId] = @WorkOrderId 
					AND WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId
					AND (WOT.[IsActive] = 1 AND WOT.[IsDeleted] = 0 AND(WOT.TaskName LIKE '%'+ @Parameter3 +'%'))

					UNION

					SELECT DISTINCT WOT.[WorkOrderTaskId] AS [Value], 
									WOT.[TaskName] AS [Label], 
									WOT.[SequenceNumber] AS [Sequence],										 
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
									CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute]										
					FROM [dbo].[WorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
					WHERE WOT.[MasterCompanyId] = @MasterCompanyId 
					AND WOT.[WorkOrderId] = @WorkOrderId 
					AND WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId
					AND WOT.[TaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
					ORDER BY [Sequence] ASC
					END
					ELSE 
					BEGIN                        
					SELECT DISTINCT WOT.[WorkOrderTaskId] AS [Value],
									WOT.[TaskName] AS [Label],
									WOT.[SequenceNumber] AS [Sequence],										 
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
									CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute]
					FROM [dbo].[WorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
					WHERE WOT.[MasterCompanyId]=@MasterCompanyId 
					AND WOT.[WorkOrderId] = @WorkOrderId 
					AND WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId
					AND WOT.[IsActive]=1 AND WOT.[IsDeleted]=0 AND WOT.[TaskName] LIKE '%'+@Parameter3+'%'
                         
					UNION
                         
					SELECT DISTINCT WOT.[WorkOrderTaskId] AS [Value],
									WOT.[TaskName] AS [Label],
									WOT.[SequenceNumber] AS [Sequence],
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
									CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute]
					FROM [dbo].[WorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
					WHERE WOT.[MasterCompanyId]=@MasterCompanyId 
					AND WOT.[WorkOrderId] = @WorkOrderId 
					AND WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId
					AND WOT.[WorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
					ORDER BY [Sequence] ASC
				END
            END
			ELSE IF(@TableName='SubWorkOrderTask')
			BEGIN
				IF(@Parameter4 = 1)
				BEGIN                      
					SELECT DISTINCT WOT.[SubWorkOrderTaskId] AS [Value], 
									WOT.[TaskName] AS [Label], 
									WOT.[SequenceNumber] AS [Sequence], 										
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
									CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute]
					FROM [dbo].[SubWorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
					WHERE WOT.[MasterCompanyId] = @MasterCompanyId 
					AND WOT.[WorkOrderId] = @WorkOrderId 
					AND WOT.SubWOPartNoId = @WorkOrderPartNumberId
					AND (WOT.[IsActive] = 1 AND WOT.[IsDeleted] = 0 AND(WOT.TaskName LIKE '%'+ @Parameter3 +'%'))

					UNION

					SELECT DISTINCT WOT.[SubWorkOrderTaskId] AS [Value], 
									WOT.[TaskName] AS [Label], 
									WOT.[SequenceNumber] AS [Sequence],										 
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
									CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute]										
					FROM [dbo].[SubWorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
					WHERE WOT.[MasterCompanyId] = @MasterCompanyId 
					AND WOT.[WorkOrderId] = @WorkOrderId 
					AND WOT.SubWOPartNoId = @WorkOrderPartNumberId
					AND WOT.[TaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
					ORDER BY [Sequence] ASC
					END
					ELSE 
					BEGIN                        
					SELECT DISTINCT WOT.[SubWorkOrderTaskId] AS [Value],
									WOT.[TaskName] AS [Label],
									WOT.[SequenceNumber] AS [Sequence],										 
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
									CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute]
					FROM [dbo].[SubWorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
					WHERE WOT.[MasterCompanyId]=@MasterCompanyId 
					AND WOT.[WorkOrderId] = @WorkOrderId 
					AND WOT.SubWOPartNoId = @WorkOrderPartNumberId
					AND WOT.[IsActive]=1 AND WOT.[IsDeleted]=0 AND WOT.[TaskName] LIKE '%'+@Parameter3+'%'
                         
					UNION
                         
					SELECT DISTINCT WOT.[SubWorkOrderTaskId] AS [Value],
									WOT.[TaskName] AS [Label],
									WOT.[SequenceNumber] AS [Sequence],
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
									CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute]
					FROM [dbo].[SubWorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
					WHERE WOT.[MasterCompanyId]=@MasterCompanyId 
					AND WOT.[WorkOrderId] = @WorkOrderId 
					AND WOT.SubWOPartNoId = @WorkOrderPartNumberId
					AND WOT.[SubWorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
					ORDER BY [Sequence] ASC
				END
			END
        END
        ELSE 
		BEGIN
            IF(@TableName='WorkOrderTask')
			BEGIN
				IF(@Parameter4 = 1)
				BEGIN				
					SELECT DISTINCT WOT.[WorkOrderTaskId] AS [Value], 
					                WOT.[TaskName] AS [Label], 
									WOT.[SequenceNumber] AS [Sequence],
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
								    CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute],
									'' AS [Descrepancy],
								    '' AS [Resolution]
                    FROM [dbo].[WorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
                    WHERE WOT.[MasterCompanyId]=@MasterCompanyId 					
					  AND WOT.[WorkOrderId] = @WorkOrderId 
				      AND WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId 
					  AND (WOT.[IsActive]=1 AND WOT.[IsDeleted]=0 AND (WOT.[TaskName] LIKE '%'+@Parameter3+'%'))
                    
					UNION
                    
					SELECT DISTINCT WOT.[WorkOrderTaskId] AS [Value], 
					                WOT.[TaskName] AS [Label], 
									WOT.[SequenceNumber] AS [Sequence], 
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
								    CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute],
									'' AS [Descrepancy],
									'' AS [Resolution]
                    FROM [dbo].[WorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
                    WHERE  WOT.[MasterCompanyId] = @MasterCompanyId 
					  AND  WOT.[WorkOrderId] = @WorkOrderId 
				      AND  WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId 
					  AND  WOT.[WorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                      ORDER BY [Sequence] ASC
                END
                ELSE
				BEGIN
						 SELECT DISTINCT WOT.[WorkOrderTaskId] AS [Value], 
						                 WOT.[TaskName] AS [Label], 
										 WOT.[SequenceNumber] AS [Sequence], 
										 CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
										 CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
										 CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute],
										 '' AS [Descrepancy],
										 '' AS [Resolution]
                         FROM [dbo].[WorkOrderTask] WOT WITH(NOLOCK)
					     LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
                         WHERE WOT.[MasterCompanyId]=@MasterCompanyId 
						 AND  WOT.[WorkOrderId] = @WorkOrderId 
				         AND  WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId 
						 AND  WOT.[IsActive]=1 AND  WOT.[IsDeleted]=0 AND  WOT.[TaskName] LIKE '%'+@Parameter3+'%'
                         
						 UNION
                         
						 SELECT DISTINCT WOT.[WorkOrderTaskId] AS [Value], 
						                 WOT.[TaskName] AS [Label], 
										 WOT.[SequenceNumber] AS [Sequence],
										 CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
										 CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
										 CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute],
										 '' AS [Descrepancy],
										 '' AS [Resolution]
                         FROM [dbo].[WorkOrderTask] WOT WITH(NOLOCK)
						 LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
                         WHERE WOT.[MasterCompanyId] = @MasterCompanyId 
						 AND WOT.[WorkOrderId] = @WorkOrderId 
				         AND WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId 
					     AND WOT.[WorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] ASC
                END
            END
			ELSE IF (@TableName='WorkOrderTask')
			BEGIN
				IF (@Parameter4 = 1)
				BEGIN				
					SELECT DISTINCT WOT.[SubWorkOrderTaskId] AS [Value], 
					                WOT.[TaskName] AS [Label], 
									WOT.[SequenceNumber] AS [Sequence],
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
								    CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute],
									'' AS [Descrepancy],
								    '' AS [Resolution]
                    FROM [dbo].[SubWorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
                    WHERE WOT.[MasterCompanyId]=@MasterCompanyId 					
					  AND WOT.[WorkOrderId] = @WorkOrderId 
				      AND WOT.SubWOPartNoId = @WorkOrderPartNumberId 
					  AND (WOT.[IsActive]=1 AND WOT.[IsDeleted]=0 AND (WOT.[TaskName] LIKE '%'+@Parameter3+'%'))
                    
					UNION
                    
					SELECT DISTINCT WOT.[SubWorkOrderTaskId] AS [Value], 
					                WOT.[TaskName] AS [Label], 
									WOT.[SequenceNumber] AS [Sequence], 
									CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
								    CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
									CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute],
									'' AS [Descrepancy],
									'' AS [Resolution]
                    FROM [dbo].[SubWorkOrderTask] WOT WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
                    WHERE  WOT.[MasterCompanyId] = @MasterCompanyId 
					  AND  WOT.[WorkOrderId] = @WorkOrderId 
				      AND  WOT.SubWOPartNoId = @WorkOrderPartNumberId 
					  AND  WOT.[SubWorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                      ORDER BY [Sequence] ASC
                END
                ELSE
				BEGIN
						 SELECT DISTINCT WOT.[SubWorkOrderTaskId] AS [Value], 
						                 WOT.[TaskName] AS [Label], 
										 WOT.[SequenceNumber] AS [Sequence], 
										 CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
										 CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
										 CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute],
										 '' AS [Descrepancy],
										 '' AS [Resolution]
                         FROM [dbo].[SubWorkOrderTask] WOT WITH(NOLOCK)
					     LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
                         WHERE WOT.[MasterCompanyId]=@MasterCompanyId 
						 AND  WOT.[WorkOrderId] = @WorkOrderId 
				         AND  WOT.SubWOPartNoId = @WorkOrderPartNumberId 
						 AND  WOT.[IsActive]=1 AND  WOT.[IsDeleted]=0 AND  WOT.[TaskName] LIKE '%'+@Parameter3+'%'
                         
						 UNION
                         
						 SELECT DISTINCT WOT.[SubWorkOrderTaskId] AS [Value], 
						                 WOT.[TaskName] AS [Label], 
										 WOT.[SequenceNumber] AS [Sequence],
										 CASE WHEN TSK.[TaskId] > 0 THEN ISNULL(TSK.[IsTravelerTask],0) ELSE 1 END [IsTravelerTask],
										 CASE WHEN TSK.[StandardHours] > 0 THEN TSK.[StandardHours] ELSE 0 END [StandardHours], 
										 CASE WHEN TSK.[StandardMinute]  > 0 THEN TSK.[StandardMinute] ELSE 0 END [StandardMinute],
										 '' AS [Descrepancy],
										 '' AS [Resolution]
                         FROM [dbo].[SubWorkOrderTask] WOT WITH(NOLOCK)
						 LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
                         WHERE WOT.[MasterCompanyId] = @MasterCompanyId 
						 AND WOT.[WorkOrderId] = @WorkOrderId 
				         AND WOT.SubWOPartNoId = @WorkOrderPartNumberId 
					     AND WOT.[SubWorkOrderTaskId] IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
                         ORDER BY [Sequence] ASC
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