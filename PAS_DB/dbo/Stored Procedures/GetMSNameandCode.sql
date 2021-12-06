CREATE PROCEDURE [dbo].[GetMSNameandCode]  
   @msID INT,  
   @Level1 varchar(200) = NULL OUTPUT,
   @Level2 varchar(200) = NULL OUTPUT,
   @Level3 varchar(200) = NULL OUTPUT,
   @Level4 varchar(200) = NULL OUTPUT
AS  
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;

BEGIN TRY
  DECLARE @1 as varchar(200) = NULL;
  DECLARE @2 as varchar(200) = NULL;
  DECLARE @3 as varchar(200) = NULL;
  DECLARE @4 as varchar(200) = NULL;

  DECLARE @ParentId  as int = 0;  
  SELECT TOP 1 @4 = MS.Code + ' - ' + MS.Name, @ParentId = MS.ParentId
  FROM dbo.ManagementStructure MS WITH (NOLOCK)
  WHERE MS.ManagementStructureId = @msID

   
  SELECT TOP 1 @3 = MS.Code + ' - ' + MS.Name, @ParentId = MS.ParentId
  FROM dbo.ManagementStructure MS WITH (NOLOCK)
  WHERE MS.ManagementStructureId = @ParentId

  SELECT TOP 1 @2 = MS.Code + ' - ' + MS.Name, @ParentId = MS.ParentId
  FROM dbo.ManagementStructure MS WITH (NOLOCK)
  WHERE MS.ManagementStructureId = @ParentId

  SELECT TOP 1 @1 = MS.Code + ' - ' + MS.Name, @ParentId = MS.ParentId
  FROM dbo.ManagementStructure MS WITH (NOLOCK)
  WHERE MS.ManagementStructureId = @ParentId
   
  IF @1 IS NOT NULL
  BEGIN
 SET @Level1 = @1;
 SET @Level2 = @2;
 SET @Level3 = @3;
 SET @Level4 = @4;
  END
  ELSE IF  @2 IS NOT NULL
  BEGIN
 SET @Level1 = @2;
 SET @Level2 = @3;
 SET @Level3 = @4;  
 SET @Level4 = NULL;
  END
  ELSE IF  @3 IS NOT NULL
  BEGIN
 SET @Level1 = @3;
 SET @Level2 = @4;
 SET @Level3 = NULL;
 SET @Level4 = NULL;
  END
  ELSE IF  @4 IS NOT NULL
  BEGIN
SET @Level1 = @4;
SET @Level2 = NULL;
SET @Level3 = NULL;
SET @Level4 = NULL;
  END
   END TRY    
BEGIN CATCH      
DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
          , @AdhocComments     VARCHAR(150)    = 'GetMSNameandCode'
          , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@msID, '') + ''''
          , @ApplicationName VARCHAR(100) = 'PAS'
-------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
          exec spLogException
                   @DatabaseName           =  @DatabaseName
                 , @AdhocComments          =  @AdhocComments
                 , @ProcedureParameters   =  @ProcedureParameters
                 , @ApplicationName        =  @ApplicationName
                 , @ErrorLogID             =  @ErrorLogID OUTPUT ;
          RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
          RETURN(1);
END CATCH
END