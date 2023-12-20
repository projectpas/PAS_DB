/*************************************************************           
 ** File:  [UpdateSpeedQuoteByID]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to update SpeedQuoteData.
 ** Purpose:         
 ** Date:   03/04/2023      
          
 ** PARAMETERS: @SpeedQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/04/2023   Amit Ghediya    Created
     
-- EXEC UpdateSpeedQuoteByID 83
************************************************************************/
CREATE      PROCEDURE [dbo].[UpdateSpeedQuoteByID]  
  @SpeedQuoteType SpeedQuoteType READONLY,
  @SpeedQuoteId BIGINT
  --@MasterCompanyId INT,
  --@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN

			IF OBJECT_ID(N'tempdb..#tmpSpeedQuote') IS NOT NULL
			BEGIN
				DROP TABLE #tmpSpeedQuote
			END
			
			CREATE TABLE #tmpSpeedQuote
			(
				ID BIGINT NOT NULL IDENTITY, 
				[SpeedQuoteId] [bigint] NULL,
				[SpeedQuoteTypeId] [INT] NULL,
				[SpeedQuoteNumber] [VARCHAR](256) NULL,
				[Version] [INT] NULL,
				[VersionNumber] [VARCHAR](256) NULL,
				[OpenDate] [datetime2](7) NULL,
				[ValidForDays] [INT] NULL,
				[QuoteExpireDate] [datetime2](7) NULL,
				[AccountTypeId] [INT] NULL,
				[CustomerId] [bigint] NULL,
				[CustomerContactId] [bigint] NULL,
				[CustomerReference] [VARCHAR](256) NULL,
				[ContractReference] [VARCHAR](256) NULL,
				[SalesPersonId] [bigint] NULL,
				[AgentName] [VARCHAR](256) NULL,
				[CustomerSeviceRepId] [bigint] NULL,
				[ProbabilityId] [bigint] NULL,
				[LeadSourceId] [INT] NULL,
				[LeadSourceReference] [VARCHAR](256) NULL,
				[CreditLimit] [decimal](20, 2) NULL,
				[CreditTermId] [INT] NULL,
				[EmployeeId] [bigint] NULL,
				[RestrictPMA] [bit] NULL,
				[RestrictDER] [bit] NULL,
				[ApprovedDate] [datetime2](7) NULL,
				[CurrencyId] [INT] NULL,
				[CustomerWarningId] [bigint] NULL,
				[Memo] [VARCHAR](256) NULL,
				[Notes] [VARCHAR](256) NULL,
				[StatusId] [INT] NULL,
				[StatusName] [VARCHAR](256) NULL,
				[StatusChangeDate] [datetime2](7) NULL,
				[ManagementStructureId] [bigint] NULL,
				[AgentId] [bigint] NULL,
				[QtyRequested] [INT] NULL,
				[QtyToBeQuoted] [INT] NULL,
				[QuoteSentDate] [datetime2](7) NULL,
				[IsNewVersionCreated] [bit] NULL,
				[QuoteParentId] [bigint] NULL,
				[QuoteTypeName] [VARCHAR](256) NULL,
				[AccountTypeName] [VARCHAR](256) NULL,
				[CustomerContactName] [VARCHAR](256) NULL,
				[CustomerContactEmail] [VARCHAR](256) NULL,
				[CustomerCode] [VARCHAR](256) NULL,
				[CustomerName] [VARCHAR](256) NULL,
				[SalesPersonName] [VARCHAR](256) NULL,
				[CustomerServiceRepName] [VARCHAR](256) NULL,
				[ProbabilityName] [VARCHAR](256) NULL,
				[LeadSourceName] [VARCHAR](256) NULL,
				[CreditTermName] [VARCHAR](256) NULL,
				[CreditLimitName] [VARCHAR](256) NULL,
				[EmployeeName] [VARCHAR](256) NULL,
				[CustomerWarningName] [VARCHAR](256) NULL,
				[CurrencyName] [VARCHAR](256) NULL,
				[Level1] [VARCHAR](256) NULL,
				[Level2] [VARCHAR](256) NULL,
				[Level3] [VARCHAR](256) NULL,
				[Level4] [VARCHAR](256) NULL,
				[EntityStructureId] [bigint] NULL,
				[MSDetailsId] [bigint] NULL,
				[LastMSLevel] [VARCHAR](256) NULL,
				[AllMSlevels] [VARCHAR](256) NULL
			)
			
			INSERT INTO #tmpSpeedQuote (SpeedQuoteId,SpeedQuoteTypeId,SpeedQuoteNumber,Version,VersionNumber,OpenDate,ValidForDays,QuoteExpireDate,AccountTypeId,CustomerId,
					CustomerContactId,CustomerReference,ContractReference,SalesPersonId,AgentName,CustomerSeviceRepId,ProbabilityId,LeadSourceId,LeadSourceReference,
					CreditLimit,CreditTermId,EmployeeId,RestrictPMA,RestrictDER,ApprovedDate,CurrencyId ,CustomerWarningId ,Memo,Notes,StatusId ,
				    StatusName ,StatusChangeDate , ManagementStructureId ,AgentId ,QtyRequested ,QtyToBeQuoted ,QuoteSentDate ,IsNewVersionCreated ,QuoteParentId ,
					QuoteTypeName ,AccountTypeName ,CustomerContactName ,CustomerContactEmail ,CustomerCode ,CustomerName ,SalesPersonName ,CustomerServiceRepName ,
					ProbabilityName ,LeadSourceName ,CreditTermName ,CreditLimitName ,EmployeeName ,CustomerWarningName ,CurrencyName ,Level1 ,Level2 ,
					Level3 ,Level4 ,EntityStructureId,MSDetailsId,LastMSLevel,AllMSlevels)
			SELECT  sqt.SpeedQuoteId,sqt.SpeedQuoteTypeId,sqt.SpeedQuoteNumber,sqt.Version,sqt.VersionNumber,sqt.OpenDate,sqt.ValidForDays,sqt.QuoteExpireDate,sqt.AccountTypeId,sqt.CustomerId,
					sqt.CustomerContactId,sqt.CustomerReference,sqt.ContractReference,sqt.SalesPersonId,sqt.AgentName,sqt.CustomerSeviceRepId,sqt.ProbabilityId,sqt.LeadSourceId,sqt.LeadSourceReference,
					sqt.CreditLimit,sqt.CreditTermId,sqt.EmployeeId,sqt.RestrictPMA,sqt.RestrictDER,sqt.ApprovedDate,sqt.CurrencyId ,sqt.CustomerWarningId ,sqt.Memo,sqt.Notes,sqt.StatusId ,
				    sqt.StatusName ,sqt.StatusChangeDate , sqt.ManagementStructureId ,sqt.AgentId ,sqt.QtyRequested ,sqt.QtyToBeQuoted ,sqt.QuoteSentDate ,sqt.IsNewVersionCreated ,sqt.QuoteParentId ,
					sqt.QuoteTypeName ,sqt.AccountTypeName ,sqt.CustomerContactName ,sqt.CustomerContactEmail ,sqt.CustomerCode ,sqt.CustomerName ,sqt.SalesPersonName ,sqt.CustomerServiceRepName ,
					sqt.ProbabilityName ,sqt.LeadSourceName ,sqt.CreditTermName ,sqt.CreditLimitName ,sqt.EmployeeName ,sqt.CustomerWarningName ,sqt.CurrencyName ,sqt.Level1 ,sqt.Level2 ,
					sqt.Level3 ,sqt.Level4 ,sqt.EntityStructureId,sqt.MSDetailsId,sqt.LastMSLevel,sqt.AllMSlevels
			FROM @SpeedQuoteType sqt;			
			
			
			UPDATE [dbo].[SpeedQuote]
			SET    SpeedQuoteTypeId =  tsp.SpeedQuoteTypeId,
				   SpeedQuoteNumber = tsp.SpeedQuoteNumber,
				   Version = tsp.Version,
				   VersionNumber = tsp.VersionNumber,
				   OpenDate = tsp.OpenDate,
				   ValidForDays = tsp.ValidForDays,
				   QuoteExpireDate = tsp.QuoteExpireDate,
				   AccountTypeId = tsp.AccountTypeId,
				   CustomerId = tsp.CustomerId,
				   CustomerContactId = tsp.CustomerContactId,
				   CustomerReference = tsp.CustomerReference,
				   ContractReference = ISNULL(tsp.ContractReference,''),
				   SalesPersonId = tsp.SalesPersonId,
				   AgentName = tsp.AgentName,
				   CustomerSeviceRepId = tsp.CustomerSeviceRepId,
				   ProbabilityId = CASE WHEN ISNULL(tsp.ProbabilityId,0) = 0 THEN  NULL ELSE tsp.ProbabilityId END,
				   LeadSourceId = tsp.LeadSourceId,
				   LeadSourceReference = tsp.LeadSourceReference,
				   CreditLimit = tsp.CreditLimit,
				   CreditTermId = tsp.CreditTermId,
				   EmployeeId = tsp.EmployeeId,
				   RestrictPMA = tsp.RestrictPMA,
				   RestrictDER = tsp.RestrictDER,
				   ApprovedDate = tsp.ApprovedDate,
				   CurrencyId = tsp.CurrencyId ,
				   CustomerWarningId = tsp.CustomerWarningId ,
				   Memo = tsp.Memo,
				   Notes = tsp.Notes,
				   StatusId = tsp.StatusId ,
				   StatusName = tsp.StatusName ,
				   StatusChangeDate = tsp.StatusChangeDate ,
				   ManagementStructureId = tsp.ManagementStructureId ,
				   AgentId = tsp.AgentId,
				   QtyRequested = tsp.QtyRequested ,
				   QtyToBeQuoted = tsp.QtyToBeQuoted ,
				   QuoteSentDate = tsp.QuoteSentDate ,
				   IsNewVersionCreated = tsp.IsNewVersionCreated ,
				   QuoteParentId = tsp.QuoteParentId ,
				   QuoteTypeName = tsp.QuoteTypeName ,
				   AccountTypeName = tsp.AccountTypeName ,
				   CustomerContactName = tsp.CustomerContactName,
				   CustomerContactEmail = tsp.CustomerContactEmail ,
				   CustomerCode = tsp.CustomerCode,
				   CustomerName = tsp.CustomerName,
				   SalesPersonName = tsp.SalesPersonName,
				   CustomerServiceRepName = tsp.CustomerServiceRepName,
				   ProbabilityName = tsp.ProbabilityName,
				   LeadSourceName = tsp.LeadSourceName,
				   CreditTermName = tsp.CreditTermName ,
				   CreditLimitName = tsp.CreditLimitName ,
				   EmployeeName = tsp.EmployeeName,
				   CustomerWarningName = tsp.CustomerWarningName,
				   CurrencyName = tsp.CurrencyName,
				   Level1 = tsp.Level1,
				   Level2 = tsp.Level2,
				   Level3 = tsp.Level3,
				   Level4 = tsp.Level4
				   --UpdatedDate = GETDATE(),
				   --UpdatedBy = @UpdatedBy,
				   --CreatedBy = @UpdatedBy,
				   --CreatedDate = GETDATE(),
				   --IsActive =1,
				   --IsDeleted = 0,
				   --MasterCompanyId = ISNULL(@MasterCompanyId,1)
				FROM #tmpSpeedQuote tsp Where tsp.SpeedQuoteId = @SpeedQuoteId;

			IF OBJECT_ID(N'tempdb..#tmpSpeedQuote') IS NOT NULL
			BEGIN
				DROP TABLE #tmpSpeedQuote
			END
		
			SELECT 
					SpeedQuoteId,
					SpeedQuoteTypeId,
					SpeedQuoteNumber,
					Version AS 'Version',
					VersionNumber,
					OpenDate,
					ValidForDays,
					QuoteExpireDate,
					AccountTypeId,
					CustomerId,
					CustomerContactId,
					CustomerReference,
					ContractReference,
					SalesPersonId,
					AgentName,
					CustomerSeviceRepId,
					ProbabilityId,
					LeadSourceId,
					LeadSourceReference,
					CreditLimit,
					CreditTermId,
					EmployeeId,
					RestrictPMA,
					RestrictDER,
					ApprovedDate,
				    CurrencyId ,
					CustomerWarningId ,
					Memo,
					Notes,
					StatusId ,
				    StatusName ,
					StatusChangeDate ,
				    ManagementStructureId ,
					AgentId ,
					QtyRequested ,
					QtyToBeQuoted ,
					QuoteSentDate ,
					IsNewVersionCreated ,
					QuoteParentId ,
					QuoteTypeName ,
					AccountTypeName ,
					CustomerContactName ,
					CustomerContactEmail ,
					CustomerCode ,
					CustomerName ,
					SalesPersonName ,
					CustomerServiceRepName ,
					ProbabilityName ,
					LeadSourceName ,
					CreditTermName ,
					CreditLimitName ,
					EmployeeName ,
					CustomerWarningName ,
					CurrencyName ,
					Level1 ,
					Level2 ,
					Level3 ,
					Level4 	
				FROM SpeedQuote Where SpeedQuoteId = @SpeedQuoteId;
		END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateSpeedQuoteByID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SpeedQuoteId, '') + ''''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH    
END