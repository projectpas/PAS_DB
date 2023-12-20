/***********************************************************************
--EXEC PROCAddUpdateAccountingMSData 47,3,2,'moin','moin',47,2,2
************************************************************************/
Create   PROCEDURE [dbo].[PROCAddUpdateAccountingMSData]
@ReferenceId bigint,
@EntityMSID bigint,
@MasterCompanyId int,
@CreatedBy varchar(256),
@UpdatedBy varchar(256),
@ModuleId int,
@Opr int,
@MSDetailsId bigint=1 OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN  
		DECLARE @MSLevel INT;
		DECLARE @LastMSName VARCHAR(200);
		DECLARE @Query VARCHAR(MAX);			

		IF(@Opr = 1)
		BEGIN	
			  IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
			  BEGIN
				DROP TABLE #TempTable
			  END
		      CREATE TABLE #TempTable(LastMSName VARCHAR(MAX)) 
			  INSERT INTO [dbo].[AccountingManagementStructureDetails]
						  ([ModuleID],[ReferenceID],[EntityMSID],
						   [Level1Id],[Level1Name],
						   [Level2Id],[Level2Name],
						   [Level3Id],[Level3Name],
						   [Level4Id],[Level4Name],
						   [Level5Id],[Level5Name],
						   [Level6Id],[Level6Name],
						   [Level7Id],[Level7Name],
						   [Level8Id],[Level8Name],
						   [Level9Id],[Level9Name],
						   [Level10Id],[Level10Name],
						   [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
			        SELECT @ModuleId,@ReferenceId,@EntityMSID,													        
							EST.Level1Id,CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description],
					        EST.Level2Id,CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description],
					        EST.Level3Id,CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description],
					        EST.Level4Id,CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description],
					        EST.Level5Id,CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description],
					        EST.Level6Id,CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description],
					        EST.Level7Id,CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description],
					        EST.Level8Id,CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description],
					        EST.Level9Id,CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description],
					        EST.Level10Id,CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description],
							@MasterCompanyId,@CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0
		 			   FROM dbo.EntityStructureSetup EST WITH(NOLOCK) 													  
							LEFT JOIN ManagementStructureLevel MSL1 WITH (NOLOCK) ON  EST.Level1Id = MSL1.ID
					        LEFT JOIN ManagementStructureLevel MSL2 WITH (NOLOCK) ON  EST.Level2Id = MSL2.ID
					        LEFT JOIN ManagementStructureLevel MSL3 WITH (NOLOCK) ON  EST.Level3Id = MSL3.ID
					        LEFT JOIN ManagementStructureLevel MSL4 WITH (NOLOCK) ON  EST.Level4Id = MSL4.ID
					        LEFT JOIN ManagementStructureLevel MSL5 WITH (NOLOCK) ON  EST.Level5Id = MSL5.ID
					        LEFT JOIN ManagementStructureLevel MSL6 WITH (NOLOCK) ON  EST.Level6Id = MSL6.ID
					        LEFT JOIN ManagementStructureLevel MSL7 WITH (NOLOCK) ON  EST.Level7Id = MSL7.ID
					        LEFT JOIN ManagementStructureLevel MSL8 WITH (NOLOCK) ON  EST.Level8Id = MSL8.ID
					        LEFT JOIN ManagementStructureLevel MSL9 WITH (NOLOCK) ON  EST.Level9Id = MSL9.ID
					        LEFT JOIN ManagementStructureLevel MSL10 WITH (NOLOCK) ON EST.Level10Id = MSL10.ID													   
					  WHERE EST.EntityStructureId=@EntityMSID; 

			  SELECT @MSDetailsId = IDENT_CURRENT('AccountingManagementStructureDetails');
			  		      
			  UPDATE dbo.CustomerRMAHeader SET ManagementStructureId = @EntityMSID WHERE RMAHeaderId = @ReferenceId; 

			  SELECT @MSLevel = MC.ManagementStructureLevel
					FROM [dbo].[MasterCompany] MC WITH(NOLOCK) 
					WHERE MC.MasterCompanyId = @MasterCompanyId;
								
			  SET @Query = N'INSERT INTO #TempTable (LastMSName) SELECT DISTINCT TOP 1 CAST ( Level' + CAST( + @MSLevel AS VARCHAR(20)) + 'Name AS VARCHAR(MAX)) FROM [dbo].[AccountingManagementStructureDetails] MSD WITH(NOLOCK) 
					WHERE MSD.MSDetailsId = CAST (' + CAST(@MSDetailsId AS VARCHAR(20)) + ' AS INT)'

			  EXECUTE(@Query)  
			  
			  UPDATE [dbo].[AccountingManagementStructureDetails] SET [LastMSLevel] = LastMSName,
							[AllMSlevels] = (SELECT AllMSlevels 
					  FROM DBO.udfGetAllEntityMSLevelString(@EntityMSID))
					FROM #TempTable WHERE MSDetailsId = @MSDetailsId;										
			  
			  IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
			  BEGIN
					DROP TABLE #TempTable
			  END             
		END
		
		IF(@Opr = 2)
		BEGIN
				IF OBJECT_ID(N'tempdb..#TempTable2') IS NOT NULL
				BEGIN
					DROP TABLE #TempTable2
				END
				CREATE TABLE #TempTable2(LastMSName VARCHAR(MAX)) 
				UPDATE [dbo].[AccountingManagementStructureDetails]
						SET [EntityMSID] = @EntityMSID, 
							[UpdatedBy] = @UpdatedBy,
							[Level1Id] = EST.Level1Id,
							[Level1Name] = CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + CAST(MSL1.[Description] AS VARCHAR(MAX)),
							[Level2Id] = EST.Level2Id,
							[Level2Name] = CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + CAST(MSL2.[Description] AS VARCHAR(MAX)),
							[Level3Id] = EST.Level3Id,														
							[Level3Name] = CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + CAST(MSL3.[Description] AS VARCHAR(MAX)),
							[Level4Id] = EST.Level4Id,														
							[Level4Name] = CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + CAST(MSL4.[Description] AS VARCHAR(MAX)),
							[Level5Id] = EST.Level5Id,														
							[Level5Name] = CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + CAST(MSL5.[Description] AS VARCHAR(MAX)),
							[Level6Id] = EST.Level6Id,														
							[Level6Name] = CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + CAST(MSL6.[Description] AS VARCHAR(MAX)),
							[Level7Id] = EST.Level7Id,														
							[Level7Name] = CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + CAST(MSL7.[Description] AS VARCHAR(MAX)),
							[Level8Id] = EST.Level8Id,														
							[Level8Name] = CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + CAST(MSL8.[Description] AS VARCHAR(MAX)),
							[Level9Id] = EST.Level9Id,														
							[Level9Name] = CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + CAST(MSL9.[Description] AS VARCHAR(MAX)),
							[Level10Id] = EST.Level10Id,
							[Level10Name] = CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + CAST(MSL10.[Description] AS VARCHAR(MAX))
					FROM [dbo].EntityStructureSetup EST WITH(NOLOCK)
							 LEFT JOIN ManagementStructureLevel MSL1 WITH (NOLOCK) ON  EST.Level1Id = MSL1.ID
							 LEFT JOIN ManagementStructureLevel MSL2 WITH (NOLOCK) ON  EST.Level2Id = MSL2.ID
							 LEFT JOIN ManagementStructureLevel MSL3 WITH (NOLOCK) ON  EST.Level3Id = MSL3.ID
							 LEFT JOIN ManagementStructureLevel MSL4 WITH (NOLOCK) ON  EST.Level4Id = MSL4.ID
							 LEFT JOIN ManagementStructureLevel MSL5 WITH (NOLOCK) ON  EST.Level5Id = MSL5.ID
							 LEFT JOIN ManagementStructureLevel MSL6 WITH (NOLOCK) ON  EST.Level6Id = MSL6.ID
							 LEFT JOIN ManagementStructureLevel MSL7 WITH (NOLOCK) ON  EST.Level7Id = MSL7.ID
							 LEFT JOIN ManagementStructureLevel MSL8 WITH (NOLOCK) ON  EST.Level8Id = MSL8.ID
							 LEFT JOIN ManagementStructureLevel MSL9 WITH (NOLOCK) ON  EST.Level9Id = MSL9.ID
							 LEFT JOIN ManagementStructureLevel MSL10 WITH (NOLOCK) ON EST.Level10Id = MSL10.ID													   
					WHERE ModuleID = @ModuleId AND ReferenceID = @ReferenceId AND EST.EntityStructureId=@EntityMSID;

					SELECT @MasterCompanyId = [MasterCompanyId], @MSDetailsId = MSDetailsId
					FROM [dbo].[AccountingManagementStructureDetails] MSD WITH(NOLOCK) 
					WHERE MSD.ModuleID = @ModuleId AND MSD.ReferenceID = @ReferenceId AND MSD.EntityMSID = @EntityMSID

					SELECT @MSLevel = MC.ManagementStructureLevel
					FROM [dbo].[MasterCompany] MC WITH(NOLOCK) 
					WHERE MC.MasterCompanyId = @MasterCompanyId

					SET @Query = N'INSERT INTO #TempTable2 (LastMSName) SELECT DISTINCT TOP 1 CAST ( Level' + CAST( + @MSLevel AS VARCHAR(20)) + 'Name AS VARCHAR(MAX)) FROM [dbo].[AccountingManagementStructureDetails] MSD WITH(NOLOCK) 
					WHERE MSD.MSDetailsId = CAST (' + CAST(@MSDetailsId AS VARCHAR(20)) + ' AS INT)'

					EXECUTE(@Query)  

					UPDATE [dbo].[AccountingManagementStructureDetails] 
						SET [LastMSLevel] = LastMSName,
							[AllMSlevels] = (SELECT AllMSlevels FROM DBO.udfGetAllEntityMSLevelString(@EntityMSID))
					FROM #TempTable2 WHERE MSDetailsId = @MSDetailsId

					SELECT @MSDetailsId = Isnull(@MSDetailsId,0);

					IF OBJECT_ID(N'tempdb..#TempTable2') IS NOT NULL
					BEGIN
						DROP TABLE #TempTable2
					END
		END
	END	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCAddUpdateAccountingMSData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ReferenceId, '') AS varchar(100))
			                                        + '@Parameter2 = ''' + CAST(ISNULL(@EntityMSID, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
													+ '@Parameter4 = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100)) 
													+ '@Parameter5 = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
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