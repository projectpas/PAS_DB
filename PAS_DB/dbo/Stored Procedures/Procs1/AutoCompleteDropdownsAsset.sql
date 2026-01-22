
/*************************************************************           
 ** File:   [AutoCompleteDropdownsAsset]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Asset List for Auto Complete Dropdown 
 ** Purpose:         
 ** Date:   12/29/2020        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/29/2020   Hemant Saliya Created
     
--EXEC [AutoCompleteDropdownsAsset] '',1,20,'70,11',1
**************************************************************/
CREATE PROCEDURE [dbo].[AutoCompleteDropdownsAsset]
@StartWith VARCHAR(50),
@IsActive bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY  

		DECLARE @Sql NVARCHAR(MAX);	
		IF(@Count = '0') 
		   BEGIN
		   set @Count='20';	
		END	
		IF(@IsActive = 1)
			BEGIN		
					SELECT DISTINCT TOP 20 
						a.AssetRecordId AS Value, 
						a.Name AS Label,		
						a.AssetRecordId,
						a.AssetId, 
						a.Name, 
						a.Description, 
						aat.AssetAttributeTypeName,
						a.TangibleClassId
					FROM dbo.Asset a WITH(NOLOCK)
						JOIN AssetAttributeType aat WITH(NOLOCK) ON a.TangibleClassId =  aat.TangibleClassId
					WHERE a.MasterCompanyId = @MasterCompanyId AND (a.IsActive=1 AND ISNULL(a.IsDeleted,0) = 0 AND (Upper(aat.AssetAttributeTypeName) = 'EQUIPMENT' OR Upper(aat.AssetAttributeTypeName) = 'TOOLS' OR Upper(aat.AssetAttributeTypeName) = 'MACHINERY')
						AND (a.Name LIKE @StartWith + '%'))
			   UNION     
					SELECT DISTINCT  
						a.AssetRecordId AS Value, 
						a.Name AS Label,		
						a.AssetRecordId,
						a.AssetId, 
						a.Name, 
						a.Description, 
						aat.AssetAttributeTypeName,
						a.TangibleClassId
					FROM dbo.Asset a WITH(NOLOCK)
						JOIN AssetAttributeType aat WITH(NOLOCK) ON a.TangibleClassId =  aat.TangibleClassId
					WHERE a.MasterCompanyId = @MasterCompanyId AND a.AssetRecordId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
				ORDER BY Label				
			End
			ELSE
			BEGIN
				SELECT DISTINCT TOP 20 
						a.AssetRecordId AS Value, 
						a.Name AS Label,		
						a.AssetRecordId,
						a.AssetId, 
						a.Name, 
						a.Description, 
						aat.AssetAttributeTypeName,
						a.TangibleClassId
					FROM dbo.Asset a  WITH(NOLOCK)
						JOIN AssetAttributeType aat WITH(NOLOCK) ON a.TangibleClassId =  aat.TangibleClassId
					WHERE a.MasterCompanyId = @MasterCompanyId AND (a.IsActive=1 AND ISNULL(a.IsDeleted,0) = 0 AND (Upper(aat.AssetAttributeTypeName) = 'EQUIPMENT' OR Upper(aat.AssetAttributeTypeName) = 'TOOLS' OR Upper(aat.AssetAttributeTypeName) = 'MACHINERY')
						AND (a.Name LIKE '%' + @StartWith + '%'))
				UNION 
				SELECT DISTINCT  
						a.AssetRecordId AS Value, 
						a.Name AS Label,		
						a.AssetRecordId,
						a.AssetId, 
						a.Name, 
						a.Description, 
						aat.AssetAttributeTypeName,
						a.TangibleClassId
					FROM dbo.Asset a WITH(NOLOCK)
						JOIN AssetAttributeType aat WITH(NOLOCK) ON a.TangibleClassId =  aat.TangibleClassId
					WHERE a.MasterCompanyId = @MasterCompanyId AND a.AssetRecordId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  
				ORDER BY Label	
			END	
	END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsAsset'
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

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);

	END CATCH
END