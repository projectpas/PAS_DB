/*************************************************************               
** File:   [GetGlAccountList]              
** Author:   Hemant Saliya  
** Description: This procedre is used to display GL Account List  
** Purpose:             
** Date:   15/02/2024  
**************************************************************               
** Change History               
**************************************************************               
** PR   Date         Author				Change Description                
** --   --------     -------			--------------------------------              
 1   15/02/2024		Hemant Saliya		Created  

DECLARE @IsRestrict INT 
EXEC dbo.USP_GetSubLadgerGLAccountRestriction 'ReconciliationPO', 1, 0, 'ADMIN User', @IsRestrict OUTPUT;
SELECT @IsRestrict
**************************************************************/   
CREATE   PROCEDURE [dbo].[USP_GetSubLadgerGLAccountRestriction](     
 @DistributionCode VARCHAR(100),
 @MasterCompanyId INT,
 @AccountingCalendarId BIGINT = NULL,
 @UpdateBy VARCHAR(200) = NULL,
 @IsRestrict BIT OUTPUT
)  
AS    
BEGIN  
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	 SET NOCOUNT ON;    
		 BEGIN TRY  
			 BEGIN
				DECLARE @DistributionMasterId BIGINT;
				DECLARE @GLAccountIds VARCHAR(MAX);
				DECLARE @SubLedgerIds VARCHAR(MAX);
				DECLARE @AccountingCalendar VARCHAR(50);
				DECLARE @ManagementStructureId BIGINT;
				DECLARE @IsAccountByPass BIT;
				DECLARE @IsRestrictAP BIT = 0;
				DECLARE @IsRestrictAR BIT = 0;
				DECLARE @IsRestrictASSET BIT = 0;
				DECLARE @IsRestrictINV BIT = 0;
				DECLARE @IsRestrictGEN BIT = 0;

				SET @IsRestrict = 0;

				SELECT @ManagementStructureId = ISNULL(ManagementStructureId,0) 
				FROM [dbo].[Employee] WITH(NOLOCK)  
				WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@UpdateBy, ' ', '')) AND MasterCompanyId = @MasterCompanyId

				IF(ISNULL(@AccountingCalendarId, 0) = 0)
				BEGIN
					SELECT TOP 1  @AccountingCalendarId = ACC.AccountingCalendarId,
								  @AccountingCalendar = PeriodName 
					FROM [dbo].[EntityStructureSetup] ES WITH(NOLOCK) 
						INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) on ES.Level1Id = MSL.ID 
						INNER JOIN [dbo].[AccountingCalendar] ACC WITH(NOLOCK) on msl.LegalEntityId = ACC.LegalEntityId AND ACC.IsDeleted =0
					WHERE ES.EntityStructureId = @ManagementStructureId AND ACC.MasterCompanyId = @MasterCompanyId 
						AND CAST(GETUTCDATE() as date) >= CAST(FromDate as date) AND CAST(GETUTCDATE() as date) <= CAST(ToDate as date)
				END

				IF OBJECT_ID(N'tempdb..#SubLedger') IS NOT NULL
				BEGIN
				  DROP TABLE #SubLedger
				END

				CREATE TABLE #SubLedger (
				  ID bigint NOT NULL IDENTITY (1, 1),
				  SubLedgerId BIGINT NULL,
				  SubLedgerName VARCHAR(100) NULL,
				  Code VARCHAR(100) NULL
				 )

				SELECT @IsAccountByPass = ISNULL(IsAccountByPass, 0) FROM dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId

				IF(@IsAccountByPass = 0)
				BEGIN
				
					SELECT DISTINCT @GLAccountIds = STRING_AGG(DS.GLAccountId, ',') , @SubLedgerIds = ISNULL(STRING_AGG(SubLedgerId, ', '), 0)
					FROM dbo.DistributionSetup DS WITH(NOLOCK) 
						JOIN dbo.DistributionMaster DM WITH(NOLOCK) ON DS.DistributionMasterId = DM.ID
						JOIN dbo.GLAccount GL WITH(NOLOCK) ON GL.GLAccountId = DS.GlAccountId
					WHERE DS.MasterCompanyId = @MasterCompanyId AND  UPPER(DM.DistributionCode) = UPPER(@DistributionCode)

					INSERT INTO #SubLedger(SubLedgerId, SubLedgerName, Code)
					SELECT SubLedgerId, [Name], Code 
					FROM dbo.SubLedger WITH(NOLOCK) 
					WHERE SubLedgerId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@SubLedgerIds, ','))

					DECLARE @TotalCount AS INT = 0;
					DECLARE @IsFristRow AS bit = 1;
					DECLARE @COUNT AS INT = 0;

					SELECT @COUNT = MAX(ID) FROM #SubLedger

					WHILE(@COUNT > 0)
					BEGIN
						DECLARE @SubLedgerId AS INT = 0;
						SELECT @SubLedgerId = SubLedgerId FROM #SubLedger WHERE ID = @COUNT
						
						SELECT 
							 @IsRestrictAR = CASE WHEN @SubLedgerId = 1 AND ISNULL(isacrStatusName, 0) = 0 THEN 1 ELSE 0 END,
							 @IsRestrictAP = CASE WHEN @SubLedgerId = 2 AND ISNULL(isacpStatusName, 0) = 0 THEN 1 ELSE 0 END,
							 @IsRestrictASSET = CASE WHEN @SubLedgerId = 3 AND ISNULL(isassetStatusName, 0) = 0 THEN 1 ELSE 0 END,
							 @IsRestrictINV = CASE WHEN @SubLedgerId = 4 AND ISNULL(isinventoryStatusName, 0) = 0 THEN 1 ELSE 0 END,
							 @IsRestrictGEN = CASE WHEN @SubLedgerId = 5 AND ISNULL(isaccStatusName, 0) = 0 THEN 1 ELSE 0 END
						FROM dbo.AccountingCalendar AC WITH(NOLOCK)  
						WHERE AccountingCalendarId = @AccountingCalendarId

						IF(ISNULL(@IsRestrictAR, 0) > 0 OR ISNULL(@IsRestrictAP, 0) > 0 OR ISNULL(@IsRestrictASSET, 0) > 0 OR ISNULL(@IsRestrictINV, 0) > 0 OR ISNULL(@IsRestrictGEN, 0) > 0)
						BEGIN
							SET @IsRestrict = 1
							GOTO SkipProcessing;
							PRINT 'SkipProcessing'
						END

						SET @COUNT = @COUNT - 1
					END
				END
				ELSE
				BEGIN
					SELECT @IsRestrict = 1 --IF Restrict at Master Complany Level
				END

				SkipProcessing: 

				IF OBJECT_ID(N'tempdb..#SubLedger') IS NOT NULL
				BEGIN
				  DROP TABLE #SubLedger
				END
			 END 
			 
		 END TRY  
	  BEGIN CATCH  
		  DECLARE @ErrorLogID INT    
		  ,@DatabaseName VARCHAR(100) = db_name()        
		  -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
		  ,@AdhocComments VARCHAR(150) = 'USP_GetReportingStructureList'        
		  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@DistributionCode, '') AS varchar(MAX))        
		  + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))      
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