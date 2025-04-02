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
 ** PR   Date          Author			Change Description            
 ** --   --------      -------			--------------------------------          
    1    09/23/2021    Hemant Saliya	Created
	2    01/03/2025    Moin Bloch  		Added field IsTravelerTask, StandardHours, StandardMinute for Task Table
	3    28 FEb 2025   RAJESH GAMI  	Order by Sequence     
	4    01/Mar/2025   Devendra Shekh	Modified (Order By [Description] ASC)
--EXEC [AutoTravelerTaskDropDownList] '',1,20,'0',1,10427
**************************************************************/
CREATE   PROCEDURE [dbo].[AutoTravelerTaskDropDownList]
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
		DECLARE @DataEnteredBy BIGINT =0
		DECLARE @Traveler_setupid AS BIGINT = 0;
		DECLARE @WorkScopeId AS BIGINT = 0;
		DECLARE @ItemMasterId AS BIGINT = 0;
		DECLARE @IstravelerTask BIT =0
        
        SELECT TOP 1 @ItemMasterId=ItemMasterId,@WorkScopeId=WorkOrderScopeId,@IstravelerTask=IsTraveler FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE ID=@WorkOrderPartId

		IF(EXISTS (SELECT 1 FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId AND IsVersionIncrease=0))
		BEGIN
		   SELECT TOP 1 @Traveler_setupid= Traveler_setupid FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId=@ItemMasterId AND IsVersionIncrease=0
		END
		ELSE IF(EXISTS (SELECT 1 FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId IS NULL AND IsVersionIncrease=0))
		BEGIN
		   SELECT TOP 1 @Traveler_setupid= Traveler_setupid FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId IS NULL AND IsVersionIncrease=0
		END

		IF(@Count = '0') 
		BEGIN
		   SET @Count='20';	
		END	
		IF(@Traveler_setupid > 0 AND @IstravelerTask=1)
		BEGIN		
					SELECT DISTINCT
						TS.[TaskId] AS Value, 
						TS.[Description] AS Label,		
						ISNULL(TSS.[Sequence],999999) AS Sequence,
						TS.[IsTravelerTask], 
						TS.[StandardHours], 
						TS.[StandardMinute]
					FROM [dbo].[Task] TS WITH(NOLOCK)
					LEFT JOIN [dbo].[Traveler_Setup_Task] TSS WITH(NOLOCK) ON ts.TaskId= tss.TaskId AND Traveler_SetupId= @Traveler_setupid
					WHERE TS.MasterCompanyId = @MasterCompanyId AND (TS.IsActive=1 AND ISNULL(TS.IsDeleted,0) = 0 
						AND (TS.[Description] LIKE @StartWith + '%')) 
			   UNION     
					SELECT DISTINCT  
						TS.[TaskId] AS Value, 
						TS.[Description] AS Label,		
						ISNULL(TSS.[Sequence],999999) AS Sequence,
						TS.[IsTravelerTask], 
						TS.[StandardHours], 
						TS.[StandardMinute]
					FROM [dbo].[Task] TS WITH(NOLOCK)
					LEFT JOIN [dbo].[Traveler_Setup_Task] TSS WITH(NOLOCK) ON ts.TaskId= tss.TaskId AND Traveler_SetupId= @Traveler_setupid
					WHERE TS.MasterCompanyId = @MasterCompanyId AND TS.TaskId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
				ORDER BY [Description] ASC				
		END
		ELSE
		BEGIN
				SELECT DISTINCT
						TS.[TaskId] AS Value, 
						TS.[Description] AS Label,	
						TS.[IsTravelerTask], 
						TS.[StandardHours], 
						TS.[StandardMinute],ISNULL(TS.[Sequence],999999) AS Sequence
					FROM [dbo].[Task] TS WITH(NOLOCK)
					WHERE TS.MasterCompanyId = @MasterCompanyId AND (ISNULL(TS.IsDeleted,0) = 0 
						AND (TS.Description LIKE '%' + @StartWith + '%'))
				UNION 
				SELECT DISTINCT  
						TS.[TaskId] AS Value, 
						TS.[Description] AS Label,		
						TS.[IsTravelerTask], 
						TS.[StandardHours], 
						TS.[StandardMinute],ISNULL(TS.[Sequence],999999) AS Sequence
					FROM [dbo].[Task] TS WITH(NOLOCK)
					WHERE TS.MasterCompanyId = @MasterCompanyId AND TS.TaskId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  
				ORDER BY [Description] ASC	
		END	
	END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoTravelerTaskDropDownList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') AS VARCHAR(100))  
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') AS VARCHAR(100))		
			   + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) 
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