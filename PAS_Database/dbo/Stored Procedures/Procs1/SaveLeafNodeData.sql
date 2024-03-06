/*************************************************************             
** File:   [SaveLeafNodeData]             
** Author:  Satish Gohil 
** Description: This stored procedure is used to Save Leaf node Data
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
3    21/08/2023  Satish Gohil   Modify(ispositive flag add at gl level)
4    27Feb2024   Rajesh Gami    Add sequence number related chane for [GLAccountLeafNodeMapping]
************************************************************************/ 
CREATE     PROCEDURE [dbo].[SaveLeafNodeData]    
(    
	@LeafNodeId BIGINT,    
	@Name VARCHAR(50),    
	@ParentId BIGINT NULL,    
	@IsLeafNode BIT NULL,    
	@GlAccountId VARCHAR(MAX) NULL,    
	@MasterCompanyId INT,    
	@CreatedBy VARCHAR(100),    
	@ReportingStructureId BIGINT,    
	@GlMappingId BIGINT,
	@IsPositive BIT
)    
AS    
BEGIN     
	BEGIN TRY            
	BEGIN        
		IF OBJECT_ID(N'tempdb..##tmpTbl') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmpTbl    
		END 
		IF OBJECT_ID(N'tempdb..#TempMain') IS NOT NULL        
		BEGIN        
			DROP TABLE #TempMain    
		END 
		
		CREATE TABLE #TempMain (
		ID INT IDENTITY(1,1),
		Item BIGINT
		);

		--DECLARE @Numbers TABLE (Number INT);
		--INSERT INTO @Numbers (Number)
		--SELECT CAST(Item AS INT) AS Number
		--FROM dbo.SplitString(@GlAccountId, ',');
		--DECLARE @SortedNumbers NVARCHAR(MAX);
		--SELECT @SortedNumbers = COALESCE(@SortedNumbers + ',', '') + CAST(Number AS NVARCHAR(MAX))
		--FROM @Numbers
		--ORDER BY Number;
		--Set @GlAccountId = @SortedNumbers

		DECLARE @SequenceNumber BIGINT =1, @DeletedLeafNodeId BIGINT = 0;
		DECLARE @MaxSequenceNumber INT= 0;  
		CREATE TABLE #tmpTbl(        
			glAccId VARCHAR(20) null    
		)       
  
		SELECT @SequenceNumber = (MAX(ISNULL(SequenceNumber,0)) +1) FROM dbo.LeafNode WITH(NOLOCK) 
		WHERE ReportingStructureId = @ReportingStructureId 

		SELECT @MaxSequenceNumber = ISNULL(MAX(SequenceNumber), 0)
		FROM dbo.GLAccountLeafNodeMapping WITH(NOLOCK)
		WHERE LeafNodeId = @LeafNodeId AND MasterCompanyId = @MasterCompanyId;


		IF(ISNULL(@LeafNodeId,0) > 0 )    
		BEGIN    
			SELECT * INTO #temp FROM [DBO].SplitString(@GlAccountId, ',')
			INSERT INTO #TempMain SELECT * FROM [DBO].SplitString(@GlAccountId, ',')
			------- Update LeafNode Data --------------    
			UPDATE dbo.LeafNode SET    
			Name = @Name,ParentId = @ParentId,    
			IsLeafNode = @IsLeafNode,GLAccountId = @GlAccountId,    
			MasterCompanyId = @MasterCompanyId,    
			UpdatedBy = @CreatedBy,UpdatedDate = GETUTCDATE(),    
			ReportingStructureId = @ReportingStructureId,    
			IsPositive = @IsPositive
			WHERE LeafNodeId = @LeafNodeId    
			PRINT 'Print1'
			IF((SELECT COUNT(1) FROM DBO.LeafNode WITH(NOLOCK) WHERE LeafNodeId = @ParentId AND ISNULL(IsLeafNode,0) = 1) > 0)
			BEGIN
			PRINT 'Under the LeafNode table'
				UPDATE [dbo].[GLAccountLeafNodeMapping]
				 SET [IsDeleted] = 1,SequenceNumber = 0
				 WHERE LeafNodeId = @ParentId

				UPDATE dbo.LeafNode SET    
				IsLeafNode = 0,GLAccountId = '',    
				MasterCompanyId = @MasterCompanyId,    
				UpdatedBy = @CreatedBy,UpdatedDate = GETUTCDATE(),    
				ReportingStructureId = @ReportingStructureId,    
				IsPositive = @IsPositive
				WHERE LeafNodeId = @ParentId
			END
			--------- Delete Gl Mapping Data -----------    
    
			--DELETE FROM dbo.GLAccountLeafNodeMapping WHERE LeafNodeId = @LeafNodeId    
    
			--------- Insert Positive Gl Mapping Data -----------    
			--IF(ISNULL(@GlAccountId,'') <> '')    
			--BEGIN    
			--	INSERT INTO dbo.GLAccountLeafNodeMapping(LeafNodeId,GLAccountId,MasterCompanyId,UpdatedBy,CreatedBy,UpdatedDate,CreatedDate,IsActive,IsDeleted,IsPositive)    
			--	SELECT @LeafNodeId,Item,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,1 FROM SplitString(@GlAccountId,',')      
    
			--	EXEC UpdateGLAccountLeafNode @LeafNodeId,@GlAccountId,@ParentId,@IsLeafNode      
			--END    

			  DELETE FROM #TempMain WHERE ISNULL(Item, '') = ''
			  MERGE [dbo].[GLAccountLeafNodeMapping] AS TARGET
			  USING #TempMain AS SOURCE ON (TARGET.LeafNodeId = @LeafNodeId AND TARGET.GLAccountId = SOURCE.Item)
			  WHEN MATCHED THEN UPDATE SET TARGET.UpdatedBy = @CreatedBy, TARGET.IsDeleted = 0, TARGET.UpdatedDate = GETUTCDATE()
			  ,TARGET.SequenceNumber = (CASE WHEN (SELECT TOP 1 SequenceNumber FROM [dbo].[GLAccountLeafNodeMapping] GLM WITH(NOLOCK) WHERE GLM.GLAccountLeafNodeMappingId = TARGET.GLAccountLeafNodeMappingId) = TARGET.SequenceNumber THEN TARGET.SequenceNumber ELSE (ISNULL((SELECT MAX(ISNULL(SequenceNumber,0)) FROM [dbo].[GLAccountLeafNodeMapping] GLM WITH(NOLOCK) WHERE GLM.LeafNodeId = @LeafNodeId AND GLM.MasterCompanyId = @MasterCompanyId),0) + 1) END)
			  WHEN NOT MATCHED BY TARGET THEN 
			  INSERT (LeafNodeId,GLAccountId,MasterCompanyId,UpdatedBy,CreatedBy,UpdatedDate,CreatedDate,IsActive,IsDeleted,IsPositive,SequenceNumber)
			  VALUES (@LeafNodeId, SOURCE.Item, @MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,1,(SOURCE.Id + @MaxSequenceNumber));

			  UPDATE [dbo].[GLAccountLeafNodeMapping]
			  SET [IsDeleted] = 1,SequenceNumber = 0
			  WHERE LeafNodeId = @LeafNodeId
			  AND [IsDeleted] = 0
			  AND [GLAccountId] NOT IN (SELECT Item FROM #TempMain)
			 
    
		END    
		ELSE    
		BEGIN     
			PRINT 'Print2'
			IF(@GlMappingId > 0)    
			BEGIN     
  			PRINT 'Print3'
				DECLARE @GlAccId VARCHAR(MAX) = ''  
  
				SELECT @GlAccId = ISNULL(GLAccountId,0) FROM dbo.LeafNode WITH(NOLOCK) WHERE LeafNodeId = @ParentId;  
    
				INSERT INTO #tmpTbl(glAccId)    
				SELECT ITEM FROM SplitString(@GlAccId,',')  
      
				IF((SELECT COUNT(*) FROM #tmpTbl) <> 1)  
				BEGIN  

					INSERT INTO dbo.LeafNode(Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate    
					,IsActive,IsDeleted,ReportingStructureId,IsPositive,SequenceNumber)    
					SELECT Name,ParentId,0,'',MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE()    
					,IsActive,IsDeleted,ReportingStructureId,0,@SequenceNumber    
					FROM dbo.LeafNode WHERE LeafNodeId = @ParentId;    
    
					SET @LeafNodeId = SCOPE_IDENTITY()    
					SET @ParentId = SCOPE_IDENTITY()    
					SET @SequenceNumber = @SequenceNumber + 1
					------- Insert LeafNode Data --------------    

					INSERT INTO dbo.LeafNode(Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate    
					,IsActive,IsDeleted,ReportingStructureId,IsPositive,SequenceNumber)    
					VALUES(@Name,@LeafNodeId,@IsLeafNode,@GlAccountId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),    
					1,0,@ReportingStructureId,@IsPositive,@SequenceNumber)    
    
					SET @LeafNodeId = SCOPE_IDENTITY()    
					
					SET @DeletedLeafNodeId = (SELECT TOP 1 LeafNodeId FROM dbo.GLAccountLeafNodeMapping WITH(NOLOCK) WHERE GLAccountLeafNodeMappingId = @GlMappingId)
					--DELETE FROM dbo.GLAccountLeafNodeMapping WHERE GLAccountLeafNodeMappingId = @GlMappingId    
					UPDATE [dbo].[GLAccountLeafNodeMapping]
					  SET [IsDeleted] = 1,SequenceNumber = 0
					  WHERE LeafNodeId = @DeletedLeafNodeId
					------- Insert Positive Gl Mapping Data -----------    
					IF(ISNULL(@GlAccountId,'') <> '' )    
					BEGIN 
						WITH NumberedSplit AS (
						SELECT 
							Item,
							ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
						FROM 
							SplitString(@GlAccountId, ',')
						)

						INSERT INTO dbo.GLAccountLeafNodeMapping(LeafNodeId,GLAccountId,MasterCompanyId,UpdatedBy,CreatedBy,UpdatedDate,CreatedDate,IsActive,IsDeleted,IsPositive,SequenceNumber)    
						SELECT @LeafNodeId,Item,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,1,@MaxSequenceNumber+RowNum FROM NumberedSplit    
    
						EXEC UpdateGLAccountLeafNode @LeafNodeId,@GlAccountId,@ParentId,@IsLeafNode      
    
					END    

					
					IF(ISNULL(@ParentId,0) > 0)      
					BEGIN      
						EXEC UpdateLeafNodeGLAccount @ParentId      
					END      
    
    
					IF(ISNULL(@GlAccountId,'') = '')    
					BEGIN    
						EXEC UpdateGLAccountLeafNode @LeafNodeId,'0',@ParentId,@IsLeafNode      
					END    
				END  
				ELSE  
				BEGIN   
					------- Insert LeafNode Data --------------    
					INSERT INTO dbo.LeafNode(Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate    
					,IsActive,IsDeleted,ReportingStructureId,IsPositive,SequenceNumber)    
					VALUES(@Name,@ParentId,@IsLeafNode,@GlAccountId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),    
					1,0,@ReportingStructureId,@IsPositive,@SequenceNumber)    
    
					SET @LeafNodeId = SCOPE_IDENTITY()    
    
					------- Insert Positive Gl Mapping Data -----------    
					IF(ISNULL(@GlAccountId,'') <> '')    
					BEGIN    
						WITH NumberedSplit AS (
						SELECT 
							Item,
							ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
							FROM 
								SplitString(@GlAccountId, ',')
							)
						INSERT INTO dbo.GLAccountLeafNodeMapping(LeafNodeId,GLAccountId,MasterCompanyId,UpdatedBy,CreatedBy,UpdatedDate,CreatedDate,IsActive,IsDeleted,IsPositive,SequenceNumber)    
						SELECT @LeafNodeId,Item,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,1,@MaxSequenceNumber+RowNum FROM NumberedSplit      
    
						EXEC UpdateGLAccountLeafNode @LeafNodeId,@GlAccountId,@ParentId,@IsLeafNode      
    
					END    

					
					IF(ISNULL(@ParentId,0) > 0)      
					BEGIN      
						EXEC UpdateLeafNodeGLAccount @ParentId      
					END      
    
    
					IF(ISNULL(@GlAccountId,'') = '')    
					BEGIN    
						EXEC UpdateGLAccountLeafNode @LeafNodeId,'0',@ParentId,@IsLeafNode      
					END    
				END  
    
			END    
			ELSE     
			BEGIN    
			PRINT 'Print4'
				------- Insert LeafNode Data --------------    
				INSERT INTO dbo.LeafNode(Name,ParentId,IsLeafNode,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate    
				,IsActive,IsDeleted,ReportingStructureId,IsPositive,SequenceNumber)    
				VALUES(@Name,@ParentId,@IsLeafNode,@GlAccountId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),    
				1,0,@ReportingStructureId,@IsPositive,@SequenceNumber)    
    
				SET @LeafNodeId = SCOPE_IDENTITY()    
    
				------- Insert Positive Gl Mapping Data -----------   
				PRINT @GlAccountId
				IF(ISNULL(@GlAccountId,'') <> '')    
				BEGIN    
					print 'GL Acccount'
					;WITH NumberedSplit AS (
						SELECT 
							Item,
							ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
						FROM 
							SplitString(@GlAccountId, ',')
					)
					INSERT INTO dbo.GLAccountLeafNodeMapping(LeafNodeId,GLAccountId,MasterCompanyId,UpdatedBy,CreatedBy,UpdatedDate,CreatedDate,IsActive,IsDeleted,IsPositive,SequenceNumber)    
					SELECT @LeafNodeId,Item,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,1,@MaxSequenceNumber+RowNum FROM NumberedSplit 
					
					--INSERT INTO dbo.GLAccountLeafNodeMapping(LeafNodeId,GLAccountId,MasterCompanyId,UpdatedBy,CreatedBy,UpdatedDate,CreatedDate,IsActive,IsDeleted,IsPositive,SequenceNumber)    
					--SELECT @LeafNodeId,Item,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,1,(ISNULL((SELECT MAX(ISNULL(SequenceNumber,0)) FROM [dbo].[GLAccountLeafNodeMapping] GLM WITH(NOLOCK) WHERE GLM.LeafNodeId = @LeafNodeId AND GLM.MasterCompanyId = @MasterCompanyId),0) + 1) FROM SplitString(@GlAccountId,',')      
    
					EXEC UpdateGLAccountLeafNode @LeafNodeId,@GlAccountId,@ParentId,@IsLeafNode       
				END   

				IF(ISNULL(@ParentId,0) > 0)      
				BEGIN      
				EXEC UpdateLeafNodeGLAccount @ParentId      
				END      
        
				IF(ISNULL(@GlAccountId,'') = '')    
				BEGIN    
					EXEC UpdateGLAccountLeafNode @LeafNodeId,'0',@ParentId,@IsLeafNode      
				END    
			END    
       
		END    
        
		SELECT ReportingStructureId FROM ReportingStructure WHERE ReportingStructureId = @ReportingStructureId      
    
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
		, @AdhocComments     VARCHAR(150)    = 'SaveLeafNodeData'         
		, @ProcedureParameters VARCHAR(3000)  = '@Name = '''+ ISNULL(@Name, '') + ''        
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