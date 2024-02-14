/*************************************************************               
** File:   [GetGlAccountList]              
** Author:   Satish Gohil  
** Description: This procedre is used to display GL Account List  
** Purpose:             
** Date:   21/07/2023  
**************************************************************               
** Change History               
**************************************************************               
** PR   Date         Author				Change Description                
** --   --------     -------			--------------------------------              
 1   21/07/2023		Satish Gohil		Created  
 2   24/07/2023		Satish Gohil		Manual JE batch Join Added  
 3	 10/10/2023		Nainshi Joshi		Add DebitAmount and CreditAmount  
 4   19/10/2023     Nainshi Joshi		Add PostedDate
 5   03/11/2023     Devendra Shekh		glaccount in-active issue resolved
 5   02/09/2024     Hemant Saliya		Added Sub Ladger

**************************************************************/   
CREATE   PROCEDURE [dbo].[GetGlAccountList](     
 @PageNumber int,    
 @PageSize int,    
 @SortColumn varchar(50)=null,    
 @SortOrder int,    
 @StatusID int,    
 @GlobalFilter varchar(50) = null,    
 @LedgerName varchar(50)=null,    
 @LeafNodeName varchar(50)=null,    
 @OldAccountCode varchar(50)=null,    
 @AccountCode varchar(50)=null,  
 @AccountName varchar(50)=null,    
 @AccountTypeId varchar(50)=null,    
 @InterCompany varchar(50)=null,    
 @AccountDescription varchar(50)=null,  
 @SubLedger varchar(50)=null,
 @CreatedDate datetime=null,    
 @UpdatedDate  datetime=null,    
 @IsDeleted bit = null,   
 @CreatedBy varchar(50)=null,    
 @UpdatedBy varchar(50)=null,    
 @MasterCompanyId int = null
)  
AS    
BEGIN  
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	 SET NOCOUNT ON;    
		 BEGIN TRY  
		 BEGIN  
			  DECLARE @RecordFrom int;  
			  DECLARE @Count Int;  
			  SET @RecordFrom = (@PageNumber-1) * @PageSize;  
			  IF @IsDeleted is null    
			  BEGIN    
			   SET @IsDeleted=0    
			  END   
			  IF @SortColumn is null   
			  BEGIN  
			   SET @SortColumn=Upper('accountCodeNum')    
			  END  
			  ELSE  
			  BEGIN  
			   SET @SortColumn=Upper(@SortColumn)  
			  END  
  
			  IF @StatusID=2    
			  BEGIN  
			   SET @StatusID=null    
			  END  
  
			  ;WITH Result AS (  
				SELECT GL.GLAccountId,  
				GL.OldAccountCode,GL.AccountCode,  
				GL.AccountName,GAL.GLAccountClassName 'AccountTypeId',  
				LG.[Name] 'LeafNodeName',  
				GL.AccountDescription,  
				GL.IsActive,GL.IsDeleted,GL.CreatedBy,GL.UpdatedBy,  
				GL.AccountCode 'AccountCodeNum',  
				SL.[Name] As 'SubLedger',
				GL.CreatedDate,GL.UpdatedDate,(ISNULL(Batch.DebitAmount, 0) + ISNULL(ManualBatch.DebitAmount, 0)) AS DebitAmount,  
				(ISNULL(Batch.CreditAmount, 0) + ISNULL(ManualBatch.CreditAmount, 0)) AS CreditAmount,ISNULL(Batch.PostedDate, 0) AS PostedDate,
				CASE WHEN ISNULL(GL.InterCompany,0) = 1 THEN 'Yes' ELSE 'No' END AS 'InterCompany',  
				CASE WHEN (Batch.GLCount > 0 OR ManualBatch.GLCount > 0) THEN 1 ELSE 0 END AS 'GlAccAdded',  
				LedgerName = STUFF((SELECT DISTINCT ', ' + L.LedgerName             
				   FROM Dbo.GLAccount G WITH(NOLOCK)   
				   LEFT JOIN DBO.GLAccountLadgerMapping GLM WITH(NOLOCK) ON G.GLAccountId = GLM.GlAccountId  
				   LEFT JOIN Dbo.[Ledger] L WITH(NOLOCK) ON GLM.LedgerId = L.LedgerId  
				   WHERE G.GLAccountId = GL.GLAccountId            
				   AND GLM.IsDeleted = 0  
				   FOR XML PATH('')            
				   ), 1, 1, '')      
			   FROM dbo.GLAccount GL WITH(NOLOCK)  
				   LEFT JOIN dbo.GLAccountClass GAL WITH(NOLOCK) ON GL.GLAccountTypeId = GAL.GLAccountClassId  
				   LEFT JOIN dbo.LeafNode LG ON GL.GLAccountNodeId = LG.LeafNodeId  
				   LEFT JOIN dbo.SubLedger SL ON SL.SubLedgerId = GL.SubLedgerId  
				   OUTER APPLY (SELECT CB.GlAccountId,COUNT(*) 'GLCount',SUM(cb.DebitAmount) AS DebitAmount,  
					SUM(cb.CreditAmount) AS CreditAmount,SUM(CASE WHEN PostedDate IS NULL THEN 1 ELSE 0 END) AS PostedDate 
					FROM dbo.CommonBatchDetails cb WITH(NOLOCK) 
					INNER JOIN BatchDetails BD ON cb.JournalBatchHeaderId = BD.JournalBatchHeaderId
					WHERE cb.GlAccountId = GL.GlAccountId AND cb.MasterCompanyId = @MasterCompanyId AND CB.IsDeleted = 0  
					GROUP BY cb.GlAccountId  
				   ) AS Batch  
				   OUTER APPLY (  
					SELECT CB.GlAccountId,COUNT(*) 'GLCount',SUM(cb.Debit) AS DebitAmount,  
					SUM(cb.Credit) AS CreditAmount  
					FROM dbo.ManualJournalDetails cb WITH(NOLOCK)   
					WHERE cb.GlAccountId = GL.GlAccountId AND cb.MasterCompanyId = @MasterCompanyId AND CB.IsDeleted = 0  
					GROUP BY cb.GlAccountId  
				   ) AS ManualBatch  
			   WHERE ((GL.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR GL.IsActive = @StatusID))  
					AND GL.MasterCompanyId = @MasterCompanyId)  
  
		  SELECT * INTO #TempResult FROM Result  
			  WHERE(  
			   (@GlobalFilter <>'' AND(  
			   (LedgerName LIKE '%' +@GlobalFilter+'%') OR   
			   (AccountCode LIKE '%' +@GlobalFilter+'%') OR   
			   (SubLedger LIKE '%' +@GlobalFilter+'%') OR   
			   (AccountName LIKE '%' +@GlobalFilter+'%') OR   
			   (AccountTypeId LIKE '%' +@GlobalFilter+'%') OR   
			   (OldAccountCode LIKE '%' +@GlobalFilter+'%') OR   
			   (AccountDescription LIKE '%' +@GlobalFilter+'%') OR  
			   (LeafNodeName LIKE '%' +@GlobalFilter+'%') OR   
			   (CreatedBy LIKE '%' +@GlobalFilter+'%') OR   
			   (UpdatedBy LIKE '%' +@GlobalFilter+'%')    
			   )) OR  
			   (@GlobalFilter='' AND     
			   (ISNULL(@LedgerName,'') ='' OR LedgerName LIKE '%' + @LedgerName+'%') AND         
			   (ISNULL(@AccountCode,'') ='' OR AccountCode LIKE '%' + @AccountCode+'%') AND 
			   (ISNULL(@SubLedger,'') ='' OR SubLedger LIKE '%' + @SubLedger+'%') AND 
			   (ISNULL(@AccountName,'') ='' OR AccountName LIKE '%' + @AccountName+'%') AND             
			   (ISNULL(@AccountTypeId,'') ='' OR AccountTypeId LIKE '%' + @AccountTypeId+'%') AND         
			   (ISNULL(@OldAccountCode,'') ='' OR OldAccountCode LIKE '%' + @OldAccountCode+'%') AND   
			   (ISNULL(@InterCompany,'') ='' OR InterCompany LIKE '%' + @InterCompany+'%') AND   
			   (ISNULL(@AccountDescription,'') ='' OR AccountDescription LIKE '%' + @AccountDescription+'%') AND             
			   (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND        
			   (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND        
			   (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND        
			   (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)))        
			  )  
  
			  SELECT @Count = COUNT(GLAccountId) FROM #TempResult   
  
			  SELECT *, @Count AS NumberOfItems FROM #TempResult    
			  ORDER BY  
			   CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,        
			   CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,        
			   CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,        
			   CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,        
			   CASE WHEN (@SortOrder=1 AND @SortColumn='LEDGERNAME')  THEN LedgerName END ASC, 
			   CASE WHEN (@SortOrder=1 AND @SortColumn='SUBLEDGER')  THEN SubLedger END ASC,    
			   CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTCODENUM')  THEN AccountCode END ASC,        
			   CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTNAME')  THEN accountCodeNum END ASC,    
			   CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTTYPEID')  THEN AccountTypeId END ASC,    
			   CASE WHEN (@SortOrder=1 AND @SortColumn='OLDACCOUNTCODE')  THEN OldAccountCode END ASC,        
			   CASE WHEN (@SortOrder=1 AND @SortColumn='INTERCOMPANY')  THEN InterCompany END ASC,    
			   CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTDESCRIPTION')  THEN AccountDescription END ASC,        
  
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,        
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,        
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,        
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,        
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='LEDGERNAME')  THEN LedgerName END DESC,   
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='SUBLEDGER')  THEN SubLedger END DESC,
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTCODENUM')  THEN accountCodeNum END DESC,        
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTNAME')  THEN AccountName END DESC,    
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTTYPEID')  THEN AccountTypeId END DESC,    
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='OLDACCOUNTCODE')  THEN OldAccountCode END DESC,        
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='INTERCOMPANY')  THEN InterCompany END DESC,    
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTDESCRIPTION')  THEN AccountDescription END DESC   
  
			   OFFSET @RecordFrom ROWS         
			   FETCH NEXT @PageSize ROWS ONLY       
			 END  
		 END TRY  
	  BEGIN CATCH  
		  DECLARE @ErrorLogID INT    
		  ,@DatabaseName VARCHAR(100) = db_name()        
		  -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
		  ,@AdhocComments VARCHAR(150) = 'USP_GetReportingStructureList'        
		  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))        
		  + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))         
		  + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))        
		  + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))        
		  + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))        
		  + '@Parameter7 = ''' + CAST(ISNULL(@AccountCode, '') AS varchar(100))        
		  + '@Parameter8 = ''' + CAST(ISNULL(@AccountName, '') AS varchar(100))        
		  + '@Parameter9 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))        
		  + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))        
		  + '@Parameter11 = ''' + CAST(ISNULL(@CreatedBy  , '') AS varchar(100))        
		  + '@Parameter12 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))        
		  + '@Parameter13 = ''' + CAST(ISNULL(@AccountTypeId , '') AS varchar(100))        
		  + '@Parameter14 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))      
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