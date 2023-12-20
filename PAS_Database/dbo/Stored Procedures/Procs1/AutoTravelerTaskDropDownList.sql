/*************************************************************           
 ** File:   [AutoCompleteDropdownsTaskStatus]           
 ** Author:   Hemant Saliya
 ** Description: This SP is used retrieve Task Status List for Auto Complete Dropdown With Code
 ** Purpose:         
 ** Date:   09/23/2021     
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/23/2021   Hemant Saliya Created
     
--EXEC [AutoTravelerTaskDropDownList] '',1,20,'0',1,10427
**************************************************************/



Create   PROCEDURE [dbo].[AutoTravelerTaskDropDownList]
@StartWith VARCHAR(50),
@IsActive bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int,
@WorkOrderPartId int=0
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY  

		DECLARE @Sql NVARCHAR(MAX);
		
		declare @DataEnteredBy bigint =0
				DECLARE @Traveler_setupid AS BIGINT = 0;
				DECLARE @WorkScopeId AS BIGINT = 0;
				DECLARE @ItemMasterId AS BIGINT = 0;
				declare @IstravelerTask bit =0
                
                select top 1 @ItemMasterId=ItemMasterId,@WorkScopeId=WorkOrderScopeId,@IstravelerTask=IsTraveler from WorkOrderPartNumber  where ID=@WorkOrderPartId

			     IF(EXISTS (SELECT 1 FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0))
				 BEGIN
				    SELECT top 1 @Traveler_setupid= Traveler_setupid FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0
				 END
				 else IF(EXISTS (SELECT 1 FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0))
				 BEGIN
				    SELECT top 1 @Traveler_setupid= Traveler_setupid FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0
				 END

		IF(@Count = '0') 
		   BEGIN
		   SET @Count='20';	
		END	
		  IF(@Traveler_setupid >0 and @IstravelerTask=1)
			BEGIN		
					SELECT DISTINCT TOP 20 
						TS.TaskId AS Value, 
						TS.Description AS Label,		
						Isnull(TSS.Sequence,999999) as Sequence
					FROM dbo.Task TS WITH(NOLOCK)
					LEFT JOIN Traveler_Setup_Task TSS WITH(NOLOCK) on ts.TaskId= tss.TaskId and Traveler_SetupId= @Traveler_setupid
					WHERE TS.MasterCompanyId = @MasterCompanyId AND (TS.IsActive=1 AND ISNULL(TS.IsDeleted,0) = 0 
						AND (TS.Description LIKE @StartWith + '%')) 
			   UNION     
					SELECT DISTINCT  
						TS.TaskId AS Value, 
						TS.Description AS Label,		
						Isnull(TSS.Sequence,999999) as Sequence
					FROM dbo.task TS WITH(NOLOCK)
					LEFT JOIN Traveler_Setup_Task TSS WITH(NOLOCK) on ts.TaskId= tss.TaskId and Traveler_SetupId= @Traveler_setupid
					WHERE TS.MasterCompanyId = @MasterCompanyId AND TS.TaskId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
				order by Sequence asc				
			End
			ELSE
			BEGIN
				SELECT DISTINCT TOP 20 
						TS.TaskId AS Value, 
						TS.Description AS Label		
					FROM dbo.task TS WITH(NOLOCK)
					WHERE TS.MasterCompanyId = @MasterCompanyId AND (ISNULL(TS.IsDeleted,0) = 0 
						AND (TS.Description LIKE '%' + @StartWith + '%'))
				UNION 
				SELECT DISTINCT  
						TS.TaskId AS Value, 
						TS.Description AS Label		
					FROM dbo.task TS WITH(NOLOCK)
					WHERE TS.MasterCompanyId = @MasterCompanyId AND TS.TaskId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  
				ORDER BY Label	
			END	
	END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsAssetByItemMaster'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))  
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))		
			   + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100)) 
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END