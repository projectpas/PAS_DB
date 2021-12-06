
/*************************************************************           
 ** File:   [AutoCompleteDropdownsItemMaster]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Publication List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   04/05/2020      
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/05/2020   Hemant Saliya Initial Created
     
--EXEC [AutoCompleteDropdownsPublicationByItemMaster] '',20,'100',245,1
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsPublicationByItemMaster]
@StartWith VARCHAR(50),
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@ItemMasterId int,
@MasterCompanyId int = 1

AS
	BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
	BEGIN TRY
			IF(@Count = '0') 
				BEGIN
				SET @Count = '20';	
			END	
				SELECT DISTINCT TOP 20 
						pb.PublicationId AS Label, 
						pb.PublicationRecordId AS Value,
						pb.ExpirationDate, 
						FileName = '',
						Link = '',
						pb.CreatedDate,
						pb.PublicationId,
						pb.PublicationRecordId
					FROM dbo.Publication pb WITH(NOLOCK) 	
					JOIN dbo.PublicationItemMasterMapping pim WITH(NOLOCK) ON pb.PublicationRecordId = pim.PublicationRecordId
					JOIN dbo.ItemMaster im WITH(NOLOCK) ON im.ItemMasterId = pim.ItemMasterId
					WHERE (pb.IsActive = 1 AND ISNULL(pb.IsDeleted, 0) = 0 AND pb.MasterCompanyId = @MasterCompanyId AND pim.ItemMasterId = @ItemMasterId
					AND (pb.PublicationId LIKE @StartWith + '%' OR pb.PublicationId  LIKE '%' + @StartWith + '%'))    
			   UNION     
					SELECT 
						pb.PublicationId AS Value, 
						pb.PublicationRecordId AS Label,
						pb.ExpirationDate, 
						FileName = '',
						Link = '',
						pb.CreatedDate,
						pb.PublicationId,
						pb.PublicationRecordId
					FROM dbo.Publication pb WITH(NOLOCK) 	
					WHERE  pb.PublicationRecordId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
				ORDER BY Label	

		END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsPublicationByItemMaster' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StartWith, '') + ''', 
													@Parameter2 = ' + ISNULL(@Count,'') + ', 
													@Parameter3 = ' + ISNULL(@Idlist,'') + ', 
													@Parameter4 = ' + ISNULL(@ItemMasterId,'') + ', 
													@Parameter5 = ' + ISNULL(@MasterCompanyId ,'') +''
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