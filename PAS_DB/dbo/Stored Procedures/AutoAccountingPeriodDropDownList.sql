
/*************************************************************             
 ** File:   [AutoAccountingPeriodDropDownList]             
 ** Author:   
 ** Description: This stored procedure is used to display accounting calendar
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	3    06/06/2023   Satish Gohil  Legal Entity parameter added

exec dbo.AutoAccountingPeriodDropDownList @TableName=N'AccountingCalendar',@Parameter1=N'AccountingCalendarId',@Parameter2=N'PeriodName',@Parameter3=N'',@Parameter4=1,@Count=20,@Idlist=N'0',@MasterCompanyId=1,@LegalEntityId = 1
**************************************************************/      
CREATE    PROCEDURE [dbo].[AutoAccountingPeriodDropDownList]        
@TableName VARCHAR(50) = null,        
@Parameter1 VARCHAR(50)= null,        
@Parameter2 VARCHAR(100)= null,        
@Parameter3 VARCHAR(50)= null,        
@Parameter4 bit = true,        
@Count VARCHAR(10)=0,        
@Idlist VARCHAR(max)='0',      
@MasterCompanyId int,
@LegalEntityId int
AS        
BEGIN    
     
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  SET NOCOUNT ON      
  BEGIN TRY      
    
      
    SELECT DISTINCT  Max(E.AccountingCalendarId) AS Value, E.PeriodName AS Label,Max(E.FromDate) as StartDate,Max(E.ToDate) as EndDate,max(FiscalYear) as FiscalYear    
    FROM dbo.AccountingCalendar E WITH(NOLOCK)     
    WHERE E.MasterCompanyId = @MasterCompanyId    
	AND LegalEntityId = @LegalEntityId
    AND (E.IsActive = 1     
    AND ISNULL(E.IsDeleted, 0) = 0    
    AND (PeriodName LIKE '%' + @Parameter3 + '%')) Group BY E.PeriodName     
    UNION     
     SELECT DISTINCT  Max(E.AccountingCalendarId)  AS Value, E.PeriodName AS Label,Max(E.FromDate) as StartDate,Max(E.ToDate) as EndDate,max(FiscalYear) as FiscalYear    
    FROM dbo.AccountingCalendar E WITH(NOLOCK)     
    WHERE E.MasterCompanyId = @MasterCompanyId AND AccountingCalendarId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
	AND LegalEntityId = @LegalEntityId
    Group BY E.PeriodName  ORDER BY EndDate,FiscalYear desc     
     
    
END TRY    
BEGIN CATCH      
 DECLARE @ErrorLogID INT    
   ,@DatabaseName VARCHAR(100) = db_name()    
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
   ,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdowns'    
   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@TableName, '') as varchar(100))    
      + '@Parameter2 = ''' + CAST(ISNULL(@Parameter1, '') as varchar(100))     
      + '@Parameter3 = ''' + CAST(ISNULL(@Parameter2, '') as varchar(100))      
      + '@Parameter4 = ''' + CAST(ISNULL(@Parameter3, '') as varchar(100))    
      + '@Parameter5 = ''' + CAST(ISNULL(@Parameter4, '') as varchar(100))     
      + '@Parameter6 = ''' + CAST(ISNULL(@Count, '') as varchar(100))      
      + '@Parameter7 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))     
      + '@Parameter8 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))     
   ,@ApplicationName VARCHAR(100) = 'PAS'    
    
  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
  EXEC spLogException @DatabaseName = @DatabaseName    
   ,@AdhocComments = @AdhocComments    
   ,@ProcedureParameters = @ProcedureParameters    
   ,@ApplicationName = @ApplicationName    
   ,@ErrorLogID = @ErrorLogID OUTPUT;    
    
  RAISERROR (    
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'    
    ,16    
    ,1    
    ,@ErrorLogID    
    )    
    
  RETURN (1);    
    
END CATCH      
END