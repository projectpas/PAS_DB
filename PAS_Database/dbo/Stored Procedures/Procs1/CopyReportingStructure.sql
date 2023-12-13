-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <3-11-2023>
-- Description:	<This SP is to copy selected Reporting Structure>
-- =============================================

 /*********************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author					Change Description              
 ** --   --------		 -------				--------------------------------            
 1		03-11-2023		Ayesha Sultana				 Created  
 2		16-11-2023		Ayesha Sultana				 Modified - version number bug fix 
 3		20-11-2023		Ayesha Sultana				 Modified - Reporting straucture name and date update 
 4		23-11-2023		Ayesha Sultana				 Modified - GLACCMAPPING bug fixes
 5		23-11-2023		Moin Bloch				     Modified - Renamed ReportingStructureId To NewReportingStructureId
  
************************************************************************/ 

CREATE    PROCEDURE [dbo].[CopyReportingStructure]
@ReportingStructureId BIGINT,
@ReportName VARCHAR(50),  
@ReportDescription VARCHAR(500),
@CreatedBy VARCHAR(50),
@UpdatedBy VARCHAR(50),
@CreatedDate DATETIME,
@UpdatedDate DATETIME
AS
BEGIN
	SET NOCOUNT ON;      
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED       
	BEGIN TRY 
	BEGIN TRANSACTION
	BEGIN
	
		INSERT INTO ReportingStructure(ReportName,ReportDescription,[IsVersionIncrease],VersionNumber,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,GlAccountClassId,IsDefault)	
		SELECT ReportName=@ReportName,ReportDescription=@ReportDescription,IsVersionIncrease, VersionNumber='VER-000001',MasterCompanyId,CreatedBy=@CreatedBy,UpdatedBy=@UpdatedBy,CreatedDate=@CreatedDate,UpdatedDate=@UpdatedDate,IsActive,IsDeleted,GlAccountClassId,IsDefault
		FROM [dbo].[ReportingStructure] WITH(NOLOCK)
		WHERE ReportingStructureId=@ReportingStructureId 

		DECLARE @updatedReportingStructureId BIGINT;
		SELECT @updatedReportingStructureId = ReportingStructureId FROM ReportingStructure

		INSERT INTO [dbo].[LeafNode]([Name],[ParentId],[IsLeafNode],[GLAccountId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ReportingStructureId],[IsPositive],[SequenceNumber])
		SELECT [Name],[ParentId],[IsLeafNode],[GLAccountId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ReportingStructureId]=@updatedReportingStructureId,[IsPositive],[SequenceNumber]
		FROM [dbo].[LeafNode] WHERE ReportingStructureId=@ReportingStructureId;

		WITH corresponding AS (
		  SELECT tp.[LeafNodeId]  AS LeafNodeId_p, tn.[LeafNodeId] AS LeafNodeId_n --, tp.SequenceNumber as SequenceNumber_p, tn.SequenceNumber as SequenceNumber_n
		  FROM [dbo].[LeafNode] tp JOIN
			   [dbo].[LeafNode] tn
			   ON tp.[Name] = tn.[Name] AND tp.SequenceNumber = tn.SequenceNumber
		  WHERE tp.ReportingStructureId = @ReportingStructureId AND tn.ReportingStructureId = @updatedReportingStructureId)

		UPDATE t
			SET [ParentId] = c.LeafNodeId_n
			FROM [dbo].[LeafNode] t JOIN corresponding c
			ON t.[ParentId] = c.LeafNodeId_p
			WHERE t.[ReportingStructureId] = @updatedReportingStructureId;

		INSERT INTO GLAccountLeafNodeMapping(LeafNodeId,GLAccountId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsPositive,NewReportingStructureId)
		SELECT G.LeafNodeId,G.GLAccountId,G.MasterCompanyId,G.CreatedBy,G.UpdatedBy,G.CreatedDate,G.UpdatedDate,G.IsActive,G.IsDeleted,G.IsPositive,@updatedReportingStructureId
		FROM [dbo].[GLAccountLeafNodeMapping] G WITH(NOLOCK)
			 JOIN [dbo].[LeafNode] L WITH(NOLOCK) ON L.LeafNodeId = G.LeafNodeId
		WHERE L.ReportingStructureId=@ReportingStructureId AND L.LeafNodeId = G.LeafNodeId;

		;WITH corresponding1 AS (
			SELECT new.[LeafNodeId] AS NEWLEAFNODES, old.[LeafNodeId] AS OLDLEAFNODES, old.ReportingStructureId AS PRID, new.ReportingStructureId AS NRID
			FROM [dbo].[LeafNode] old JOIN
				 [dbo].[LeafNode] new
				 ON old.[Name] = new.[Name]
			WHERE old.ReportingStructureId = @ReportingStructureId and new.ReportingStructureId=@updatedReportingStructureId )

		UPDATE [dbo].[GLAccountLeafNodeMapping]
			SET [LeafNodeId] = c.NEWLEAFNODES
			FROM [dbo].[GLAccountLeafNodeMapping] G JOIN corresponding1 c ON G.LeafNodeId = c.OLDLEAFNODES
			WHERE G.LeafNodeId = c.OLDLEAFNODES AND G.NewReportingStructureId = @updatedReportingStructureId;
	
		END

	COMMIT  TRANSACTION
		
	END TRY  
	BEGIN CATCH  
	    IF @@trancount > 0
	    ROLLBACK TRAN;
		DECLARE @ErrorLogID INT ,@DatabaseName VARCHAR(100) = db_name()      
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
		,@AdhocComments VARCHAR(150) = 'CopyReportingStructure'      
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReportingStructureId, '') AS varchar(100))      
											+ '@Parameter2 = ''' + CAST(ISNULL(@ReportName, '') AS varchar(100))       
											+ '@Parameter3 = ''' + CAST(ISNULL(@ReportDescription, '') AS varchar(100))      
		,@ApplicationName VARCHAR(100) = 'PAS'      
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
		EXEC spLogException @DatabaseName = @DatabaseName      
								,@AdhocComments = @AdhocComments      
								,@ProcedureParameters = @ProcedureParameters      
								,@ApplicationName = @ApplicationName      
								,@ErrorLogID = @ErrorLogID OUTPUT;          
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)      
      
		RETURN (1);    
	END CATCH 
END