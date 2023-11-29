/*************************************************************             
** File:   [USP_CreateLeafNode_Version]             
** Author:  Satish Gohil 
** Description: This stored procedure is used to Save Leaf node with new version
** Purpose:           
** Date:   05/22/2023
 
** RETURN VALUE:             
**************************************************************             
** Change History             
**************************************************************             
** PR   Date         Author  Change Description              
** --   --------     -------  --------------------------------            
1    05/22/2023  Satish Gohil   Gl Account Link issue fixed
2    06/05/2023  Satish Gohil   Modify(IsParent Column Added)
3    06/07/2023  Satish Gohil   Modify(Sequence Number Added)
4	 21/08/2023  Satish Gohil   Modify(Added Gl Account level ispositive flag)
************************************************************************/ 

CREATE    PROCEDURE DBO.USP_CreateLeafNode_Version      
(      
	@tbl_LeafNodeType LeafNodeType Readonly,      
	@updatedByName varchar(50) = NULL,        
	@MstCompanyId bigint = NULL,      
	@ReportingStructureId bigint = null,    
	@GlMappingId BIGINT         
)      
AS      
BEGIN      
	SET NOCOUNT ON;        
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED        
	BEGIN TRY        
	BEGIN        
		DECLARE @TotalDistictRecord int = 0, @TotalRecord int = 0;      
		DECLARE @NewReportingStructureId BIGINT;      
		DECLARE @ID BIGINT = 0;      
		DECLARE @GlAccountId varchar(max) ='';      
		DECLARE @ParentId BIGINT = 0;      
		DECLARE @IsLeafNode BIT = 0;      
		DECLARE @MinId BIGINT = 1;      
		DECLARE @GlAccId VARCHAR(20) = '0'; 
		DECLARE @SequenceNumber BIGINT = 1;
		DECLARE @TotalGlRecord int = 0, @MinGL int = 0;   
		DECLARE @IsPositiveGL BIT = 1;
		DECLARE @LFMappingId BIGINT = 0;     

		
		IF OBJECT_ID(N'tempdb..#temptable') IS NOT NULL        
		BEGIN        
			DROP TABLE #temptable        
		END        
        
		IF OBJECT_ID(N'tempdb..#temptable2') IS NOT NULL        
		BEGIN        
			DROP TABLE #temptable2        
		END        
    
		IF OBJECT_ID(N'tempdb..#temptable3') IS NOT NULL        
		BEGIN        
			DROP TABLE #temptable3    
		END        
    
		IF OBJECT_ID(N'tempdb..##tmpTbl') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmpTbl    
		END     
        
		
		CREATE TABLE #tmpTbl(        
			[rowId] [bigint] NULL,    
			glAccId VARCHAR(20) null    
		)      
    
		CREATE TABLE #temptable      
		(      
			rownumber int identity(1,1),      
			LeafNodeId bigint NULL,      
			Name varchar(50) NULL,      
			ParentId bigint NULL,      
			IsLeafNode bit NULL,      
			GLAccountId varchar(max) NULL,      
			MasterCompanyId bigint NULL,      
			CreatedBy varchar(50) NULL,      
			UpdatedBy varchar(50) NULL,      
			CreatedDate [datetime2](7) NULL,      
			UpdatedDate [datetime2](7) NULL,      
			IsActive bit,      
			IsDeleted bit,      
			ReportingStructureId bigint,      
			GlMappingId bigint,    
			NewLeafNodeId bigint,
			IsPositive BIT
		)        
    
		CREATE TABLE #temptable3      
		(      
			rownumber int identity(1,1),      
			LeafNodeId bigint NULL,      
			Name varchar(50) NULL,      
			ParentId bigint NULL,      
			IsLeafNode bit NULL,      
			GLAccountId varchar(max) NULL,      
			MasterCompanyId bigint NULL,      
			CreatedBy varchar(50) NULL,      
			UpdatedBy varchar(50) NULL,      
			CreatedDate [datetime2](7) NULL,      
			UpdatedDate [datetime2](7) NULL,      
			IsActive bit,      
			IsDeleted bit,      
			ReportingStructureId bigint,      
			GlMappingId bigint,    
			NewLeafNodeId bigint,      
			IsPositive BIT,
			SequenceNumber BIGINT
		)        
      
		CREATE TABLE #temptable2      
		(      
			rownumber int identity(1,1),      
			LeafNodeId bigint NULL,      
			ParentId bigint NULL,      
			IsLeafNode bit NULL,      
			GLAccountId varchar(max),      
			ReportingStructureId bigint 
		)      
      
		SELECT @GlAccId = ISNULL(GlAccountId,'0') FROM dbo.GLAccountLeafNodeMapping WITH(NOLOCK) 
		WHERE GLAccountLeafNodeMappingId = @GlMappingId;     

		---------- Insert New Reporting Strucutre -------------      
		INSERT INTO dbo.ReportingStructure(ReportName,ReportDescription,IsVersionIncrease,VersionNumber,      
		MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,GlAccountClassId)      
		SELECT ReportName,ReportDescription,0,VersionNumber,      
		MasterCompanyId,@updatedByName,@updatedByName,GETUTCDATE(),GETUTCDATE(),IsActive,IsDeleted,GlAccountClassId      
		FROM ReportingStructure WHERE ReportingStructureId = @ReportingStructureId      
      
		SET @NewReportingStructureId = SCOPE_IDENTITY();      
      
		EXEC UpdateReportingStructureVersionNo @NewReportingStructureId,1      
      
		UPDATE dbo.ReportingStructure SET IsVersionIncrease = 1 WHERE ReportingStructureId = @ReportingStructureId      
        
      
		-------- Insert New Reporting Strucutre -------------
		
		INSERT INTO #temptable(LeafNodeId,Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,      
		UpdatedDate,IsActive,IsDeleted,ReportingStructureId,GlMappingId,NewLeafNodeId,IsPositive)      
		SELECT LeafNodeId,Name,ParentId,IsLeafNode,GLAccountId,@MstCompanyId,@updatedByName,@updatedByName,GETUTCDATE(),      
		GETUTCDATE(),1,0,ReportingStructureId,@GlMappingId,null,IsPositive      
		FROM @tbl_LeafNodeType      
      
		-------- Insert Record In Final Temp Table -------------      

		IF(ISNULL(@GlAccId,'0') <> '0')    
		BEGIN    
			SELECT @ID =TB1.rownumber,@GlAccountId = TB1.GLAccountId     
			FROM #temptable TB2 WITH(NOLOCK)      
			INNER JOIN #temptable TB1 ON TB1.LeafNodeId = TB2.ParentId      
			WHERE TB2.LeafNodeId = 0    
    
			INSERT INTO #tmpTbl(rowId,glAccId)    
			SELECT @ID,ITEM FROM SplitString(@GlAccountId,',')    
       
    
			SELECT @GlAccountId =     
			STUFF((SELECT DISTINCT ',' + glAccId    
			FROM #tmpTbl T2    
			WHERE T2.glAccId <> @GlAccId    
			FOR XML PATH ('')),1,1,'')    
			FROM #tmpTbl T    
    
			UPDATE TB1      
			SET TB1.GLAccountId = @GlAccountId    
			FROM #temptable TB2 WITH(NOLOCK)      
			INNER JOIN #temptable TB1 ON TB1.LeafNodeId = TB2.ParentId      
			WHERE TB2.LeafNodeId = 0    
    
		END    

		DECLARE @MappingId bigint =0;    
		DECLARE @LeafNodeId bigint =0;    
    
		SELECT @TotalRecord = COUNT(*), @MinId = MIN(rownumber) FROM #temptable      
		WHILE @MinId <= @TotalRecord      
		BEGIN       
			SELECT @MappingId = isnull(GlMappingId,0),@LeafNodeId = LeafNodeId,@ParentId = ParentId 
			FROM #temptable WHERE rownumber = @MinId    
     
			IF(@MappingId > 0 and @LeafNodeId = 0)        
			BEGIN     
  
				SELECT @GlAccountId = ISNULL(GLAccountId,0) FROM dbo.LeafNode WITH(NOLOCK)
				WHERE LeafNodeId = @ParentId;  
     
  
				IF((SELECT COUNT(*) FROM #tmpTbl) <> 1)  
				BEGIN  
					INSERT INTO #temptable3(LeafNodeId,[Name],ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,          
					UpdatedDate,IsActive,IsDeleted,ReportingStructureId,GlMappingId,NewLeafNodeId,IsPositive,SequenceNumber)          
					SELECT LeafNodeId,[Name],ParentId,0,'',MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,          
					UpdatedDate,IsActive,IsDeleted,ReportingStructureId,GlMappingId,NewLeafNodeId,IsPositive,@SequenceNumber    
					FROM #temptable WHERE LeafNodeId = @ParentId        
    
					SET @SequenceNumber = @SequenceNumber + 1

					INSERT INTO #temptable3(LeafNodeId,[Name],ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,          
					UpdatedDate,IsActive,IsDeleted,ReportingStructureId,GlMappingId,NewLeafNodeId,IsPositive,SequenceNumber)          
					SELECT LeafNodeId,Name,SCOPE_IDENTITY(),IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,          
					UpdatedDate,IsActive,IsDeleted,ReportingStructureId,GlMappingId,NewLeafNodeId,IsPositive,@SequenceNumber    
					FROM #temptable WHERE rownumber = @MinId          

					SET @SequenceNumber = @SequenceNumber + 1

				END  
				ELSE  
				BEGIN  
					INSERT #temptable3(LeafNodeId,Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,          
					UpdatedDate,IsActive,IsDeleted,ReportingStructureId,GlMappingId,NewLeafNodeId,IsPositive,SequenceNumber)          
					SELECT LeafNodeId,Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,          
					UpdatedDate,IsActive,IsDeleted,ReportingStructureId,GlMappingId,NewLeafNodeId,IsPositive,@SequenceNumber    
					FROM #temptable WHERE rownumber = @MinId       

					SET @SequenceNumber = @SequenceNumber + 1
				END  
			END    
			ELSE    
			BEGIN     
				INSERT #temptable3(LeafNodeId,Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,          
				UpdatedDate,IsActive,IsDeleted,ReportingStructureId,GlMappingId,NewLeafNodeId,IsPositive,SequenceNumber)          
				SELECT LeafNodeId,Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,          
				UpdatedDate,IsActive,IsDeleted,ReportingStructureId,GlMappingId,NewLeafNodeId,IsPositive,@SequenceNumber    
				FROM #temptable WHERE rownumber = @MinId 
  
				SET @SequenceNumber = @SequenceNumber + 1
			END    
    
			SET @MinId = @MinId + 1;      
    
		END    
    
		-------- Insert Record In Final Temp Table -------------      
    
		

		---------- Insert Record in Leaf Node -------------      
    
		SELECT @TotalRecord = COUNT(*), @MinId = MIN(rownumber) FROM #temptable3      
		DECLARE @NewLeafNodeId BIGINT
		WHILE @MinId <= @TotalRecord      
		BEGIN      
			INSERT INTO dbo.LeafNode(Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,      
			UpdatedDate,IsActive,IsDeleted,ReportingStructureId,IsPositive,SequenceNumber)      
			SELECT Name,ParentId,IsLeafNode,GLAccountId ,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,      
			UpdatedDate,IsActive,IsDeleted,@NewReportingStructureId,IsPositive,SequenceNumber      
			FROM #temptable3 WHERE rownumber = @MinId      
          
			UPDATE TMP      
			SET NewLeafNodeId = SCOPE_IDENTITY()      
			FROM #temptable3 TMP      
			WHERE TMP.rownumber = @MinId      
    
			SET @NewLeafNodeId = SCOPE_IDENTITY()       
		
			SELECT @GlAccountId = GLAccountId,@LeafNodeId = LeafNodeId
			from #temptable3 where rownumber = @MinId      
             
			IF (ISNULL(@GlAccountId,'') <> '' AND @LeafNodeId = 0)      
			BEGIN       
				
				INSERT INTO dbo.GLAccountLeafNodeMapping(LeafNodeId,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy      
				,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsPositive)      
				SELECT @NewLeafNodeId,ITEM,@MstCompanyId,@updatedByName,@updatedByName,GETUTCDATE(),GETUTCDATE(),1,0,1      
				FROM SplitString(@GlAccountId,',')      

			END  
			
			IF (ISNULL(@GlAccountId,'') <> '' AND @LeafNodeId > 0)      
			BEGIN
				
				IF OBJECT_ID(N'tempdb..#tmpReturnTbl') IS NOT NULL        
				BEGIN        
					DROP TABLE #tmpReturnTbl        
				END 

				CREATE TABLE #tmpReturnTbl( 
					rownumber int identity(1,1),  
					[GlAccId] [bigint] NULL
				)      
      

				INSERT INTO #tmpReturnTbl([GlAccId])    
				SELECT ITEM FROM SplitString(@GlAccountId,',')

				SELECT @TotalGlRecord = COUNT(*), @MinGL = MIN(rownumber) FROM #tmpReturnTbl  
				
				DECLARE @GlAccount BIGINT;

				WHILE @MinGL <= @TotalGlRecord 
				BEGIN
					SELECT @GlAccount = GlAccId FROM #tmpReturnTbl WHERE rownumber = @MinGL
					
					SELECT TOP 1 @IsPositiveGL = IsPositive,@LFMappingId = GLAccountLeafNodeMappingId 
					FROM dbo.GLAccountLeafNodeMapping WITH(NOLOCK) 
					WHERE LeafNodeId = @LeafNodeId AND GLAccountId = @GlAccount and IsDeleted = 0
					
					IF(ISNULL(@LFMappingId,0) <> 0)
					BEGIN
						
						INSERT INTO dbo.GLAccountLeafNodeMapping(LeafNodeId,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy      
						,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsPositive)      
						VALUES(@NewLeafNodeId,@GlAccount,@MstCompanyId,@updatedByName,@updatedByName,GETUTCDATE(),GETUTCDATE(),1,0,@IsPositiveGL)
					END
					ELSE
					BEGIN
						
						INSERT INTO dbo.GLAccountLeafNodeMapping(LeafNodeId,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy      
						,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsPositive)      
						VALUES(@NewLeafNodeId,@GlAccount,@MstCompanyId,@updatedByName,@updatedByName,GETUTCDATE(),GETUTCDATE(),1,0,1)     
						
					END

					SET @MinGL = @MinGL +1
				END

			END
      
			SET @MinId = @MinId + 1;
		END      
      
		-------- Insert Record in Leaf Node -------------      
	

		-------- Update ParentID in Leaf Node -------------     
		SELECT @MappingId = isnull(GlMappingId,0),@MinId = rownumber FROM #temptable3 
		WHERE LeafNodeId = 0 AND GlMappingId > 0    
		
		IF(ISNULL(@MappingId,0) > 0 )    
		BEGIN    
			UPDATE TB2      
			SET TB2.ParentId = TB1.NewLeafNodeId      
			FROM dbo.LeafNode TB2 WITH(NOLOCK)      
			INNER JOIN #temptable3 TB1 ON TB1.LeafNodeId = TB2.ParentId      
			WHERE TB2.ParentId IS NOT NULL AND TB2.ReportingStructureId = @NewReportingStructureId  AND TB1.LeafNodeId <> 0    
    
			UPDATE TB2      
			SET TB2.ParentId = TB3.NewLeafNodeId      
			FROM dbo.LeafNode TB2 WITH(NOLOCK)      
			INNER JOIN #temptable3 TB1 ON TB2.LeafNodeId = TB1.NewLeafNodeId    
			INNER JOIN #temptable3 TB3 ON TB1.ParentId = TB3.rownumber    
    
		END    
		ELSE    
		BEGIN    
			UPDATE TB2      
			SET TB2.ParentId = TB1.NewLeafNodeId      
			FROM dbo.LeafNode TB2 WITH(NOLOCK)      
			INNER JOIN #temptable3 TB1 ON TB1.LeafNodeId = TB2.ParentId      
			WHERE TB2.ParentId IS NOT NULL AND TB2.ReportingStructureId = @NewReportingStructureId      
		END    
      
		-------- Update ParentID in Leaf Node -------------      
    
		------ Update GL Account  -------------        
		DECLARE @TOTALTMP2COUNT BIGINT = 0;      
		DECLARE @MINTMP2ID BIGINT = 1;      
      
		INSERT INTO #temptable2(LeafNodeId,ParentId,IsLeafNode,GLAccountId,ReportingStructureId)      
		SELECT LeafNodeId,ISNULL(ParentId,0),ISNULL(IsLeafNode,0),ISNULL(GLAccountId,''),ReportingStructureId      
		FROM dbo.LeafNode WITH(NOLOCK) WHERE ReportingStructureId = @NewReportingStructureId      
      
		SELECT @TOTALTMP2COUNT = COUNT(*),@MINTMP2ID = MIN(rownumber) FROM #temptable2      
      
		WHILE @MINTMP2ID <= @TOTALTMP2COUNT      
		BEGIN      
			SELECT @ID = LeafNodeId,@GlAccountId = GLAccountId,@ParentId = ParentId,@IsLeafNode =IsLeafNode FROM #temptable2      
			WHERE rownumber = @MINTMP2ID      
      
			EXEC dbo.UpdateGLAccountLeafNode @ID,@GlAccountId,@ParentId,@IsLeafNode      
      
      
			IF(@ParentId > 0)      
			BEGIN      
				EXEC dbo.UpdateLeafNodeGLAccount @ParentId      
			END      
        
			SET @MINTMP2ID = @MINTMP2ID + 1;      
      
		END      
         
		-------- Update GL Account  -------------      
      
		SELECT ReportingStructureId FROM dbo.ReportingStructure WITH(NOLOCK)
		WHERE ReportingStructureId = @NewReportingStructureId      
      
	END      
	END TRY      
	BEGIN CATCH      
		SELECT        
		ERROR_NUMBER() AS ErrorNumber,        
		ERROR_STATE() AS ErrorState,        
		ERROR_SEVERITY() AS ErrorSeverity,        
		ERROR_PROCEDURE() AS ErrorProcedure,        
		ERROR_LINE() AS ErrorLine,        
		ERROR_MESSAGE() AS ErrorMessage;        
		IF @@trancount > 0        
		PRINT 'ROLLBACK'        
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
		, @AdhocComments     VARCHAR(150)    = 'USP_CreateLafNode'         
		, @ProcedureParameters VARCHAR(3000)  = '@MstCompanyId = '''+ ISNULL(@MstCompanyId, '') + ''        
		, @ApplicationName VARCHAR(100) = 'PAS'        
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
		exec spLogException         
		@DatabaseName           = @DatabaseName        
		, @AdhocComments          = @AdhocComments        
		, @ProcedureParameters = @ProcedureParameters        
		, @ApplicationName        =  @ApplicationName        
		, @ErrorLogID             = @ErrorLogID OUTPUT ;        
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)        
		RETURN(1);       
	END CATCH      
END