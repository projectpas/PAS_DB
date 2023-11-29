
/*************************************************************           
 ** File:   [GetAccountingReportStructureData]           
 ** Author:   Satish Gohil
 ** Description: This stored procedure is used VendorPaymentList
 ** Purpose:         
 ** Date:   20/06/2023   
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    20/06/2023   Satish Gohil  Created
	
**************************************************************/

CREATE   PROCEDURE [dbo].[GetAccountingReportStructureData]
(
	@ReportingStructureId BIGINT,
	@FromDate datetime,
	@Todate datetime,
	@MasterCompanyId int
)
AS
BEGIN
		BEGIN TRY
			IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL    
			BEGIN    
				DROP TABLE #TempTable    
			END
			
			DECLARE @COUNT BIGINT;
			DECLARE @ID INT = 1;  
			DECLARE @PARENTID BIGINT; 
			DECLARE @Amount DECIMAL(18,2); 

			CREATE TABLE #TempTable (     
				ID BIGINT NOT NULL IDENTITY(1,1),  
				LeafNodeId BIGINT,  
				Name varchar(MAX),
				ParentId BIGINT,
				GlAccountId Int,
				GlAccountName varchar(MAX),
				Amount decimal(18,2)
			)  

			INSERT INTO #TempTable(LeafNodeId,Name,ParentId,GlAccountId,GlAccountName,Amount)
			SELECT L.LeafNodeId,L.Name,L.ParentId,GLM.GLAccountId,GL.AccountName,ISNULL(CBD.CreditAmount,0)
			FROM dbo.LeafNode L WITH(NOLOCK)
			LEFT JOIN dbo.GLAccountLeafNodeMapping GLM WITH(NOLOCK) ON L.LeafNodeId = GLM.LeafNodeId
			LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON GLM.GLAccountId = GL.GLAccountId
			OUTER APPLY(
				SELECT cb.GLAccountId,SUM(ISNULL(cb.CreditAmount,0)) 'CreditAmount' FROM dbo.CommonBatchDetails cb WITH(NOLOCK) 
				WHERE GLM.GLAccountId = cb.GlAccountId AND CAST(cb.TransactionDate AS date) BETWEEN CAST(@FromDate AS date) AND CAST(@Todate AS date)
				GROUP BY cb.GlAccountId
			)CBD
			WHERE L.ReportingStructureId = @ReportingStructureId AND L.IsDeleted = 0 and L.MasterCompanyId = @MasterCompanyId
			ORDER BY L.LeafNodeId

			SELECT @COUNT = COUNT(*) FROM #TempTable 

			WHILE @COUNT >= @ID
			BEGIN
				SELECT @PARENTID = ISNULL(ParentId,0),@Amount = ISNULL(AMOUNT,0)  FROM #TempTable WHERE ID = @COUNT

				UPDATE T1
				SET Amount = ISNULL(T1.Amount,0) + @Amount
				FROM #TempTable T1
				WHERE T1.LeafNodeId = @PARENTID

				SET @COUNT = @COUNT -1
			END			

			SELECT * FROM #TempTable ORDER BY ID DESC

		END TRY
		BEGIN CATCH
		END CATCH
END