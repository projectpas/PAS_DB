    
/*************************************************************               
 ** File:   [UpdateReportingStructureVersionNo]               
 ** Author:   Satish Gohil    
 ** Description: This stored procedure is used Update Reporting Structure Version Number     
 ** Purpose:             
 ** Date:   10/04/2023           
              
 ** PARAMETERS:               
 @UserType varchar(60)       
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author		Change Description                
 ** --   --------     -------		--------------------------------              
    1    10/04/2023   Satish Gohil	Created    
         
-- EXEC [UpdateReportingStructureVersionNo] 50, 1    
**************************************************************/    
    
CREATE   PROCEDURE [dbo].[UpdateReportingStructureVersionNo]    
@ReportingStructureId INT,    
@IsVersionIncrease BIT    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 DECLARE @VersionNo VARCHAR(20);    
 DECLARE @Version VARCHAR(20);    
 DECLARE @SplitChar VARCHAR(20);    
 DECLARE @VersionPrefix VARCHAR(20);    
 SET @SplitChar = '-';    
     
    
  BEGIN TRY    
   BEGIN      
    IF(@IsVersionIncrease = 1)    
    BEGIN    
     SELECT @VersionNo = VersionNumber FROM dbo.ReportingStructure WITH(NOLOCK) WHERE ReportingStructureId = @ReportingStructureId;    
    
     IF OBJECT_ID(N'tempdb..#CodePrifix') IS NOT NULL    
     BEGIN    
     DROP TABLE #CodePrifix    
     END    
     
     CREATE TABLE #CodePrifix    
     (    
       ID BIGINT NOT NULL IDENTITY,     
       items VARCHAR(100) NULL    
     )    
    
     INSERT INTO #CodePrifix (items) SELECT Item FROM DBO.SPLITSTRING(@VersionNo, @SplitChar)    
     SELECT @VersionPrefix = items FROM #CodePrifix WHERE ID = 1    
     SELECT @Version = items FROM #CodePrifix WHERE ID = 2         
         
     IF(@VersionNo != '' OR @VersionNo != NULL)    
     BEGIN    
      IF(CHARINDEX ('-',@VersionNo) > 0)    
      --IF(LEN(@VersionNo) >= 5)    
      BEGIN    
       --SET @Version = STUFF(@VersionNo,1,4,'')    
       --SELECT @Version;    
       --SET @Version = 'V' + CAST(CAST(@Version AS INT) + 1 AS VARCHAR(20));    
       SET @Version = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@Version AS INT) + 1, @VersionPrefix, ''))    
      END    
      ELSE    
      BEGIN    
       --SET @Version = STUFF(@VersionNo,1,1,'')    
       --SET @Version = 'V' + CAST(CAST(@Version AS INT) + 1 AS VARCHAR(20));    
       SET @Version = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@Version AS INT) + 1,'VER', ''))    
      END    
     END    
     ELSE    
     BEGIN    
      --SET @Version = 'VER-00001';    
      SET @Version = (SELECT * FROM dbo.udfGenerateCodeNumber(1,'VER', ''))    
     END    
    
     UPDATE Rep      
      SET Rep.VersionNumber = @Version         
     FROM [dbo].[ReportingStructure] Rep WITH(NOLOCK)   
     WHERE Rep.ReportingStructureId = @ReportingStructureId  
    END    
        
   END    
  END TRY        
  BEGIN CATCH          
   IF @@trancount > 0    
    PRINT 'ROLLBACK'    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'UpdateReportingStructureVersionNo'     
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ReportingStructureId, '') AS varchar(MAX)) + ''    
              , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
    
              exec spLogException     
                       @DatabaseName           = @DatabaseName    
                     , @AdhocComments          = @AdhocComments    
                     , @ProcedureParameters    = @ProcedureParameters    
                     , @ApplicationName        =  @ApplicationName    
                     , @ErrorLogID           = @ErrorLogID OUTPUT ;    
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
              RETURN(1);    
  END CATCH    
END