
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.AutoCompleteDropdownsSalesorderItemMaster   (source: PAS_DB/dbo/Stored Procedures/Procs1/AutoCompleteDropdownsSalesorderItemMaster.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [AutoCompleteDropdownsSalesorderItemMaster]           
 ** Author:   HEMANT SALIYA
 ** Description: This stored procedure is used retrieve work Order Item Master List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   01/07/2022      
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    18/10/2024   AMIT GHEDIYA		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    22/July/2026			 RAJESH GAMI						[PN-17350] - Removed leftover IsNonStock=0 Stock-only exclusion filters added during PN-17008/PN-17009 transitional Non-Stock merge phase (Non-Stock is now merged; filters are no longer needed)
     
--EXEC [AutoCompleteDropdownsSalesorderItemMaster] '5',20,'',1110
**************************************************************/
CREATE       PROCEDURE [dbo].[AutoCompleteDropdownsSalesorderItemMaster]
	@StartWith VARCHAR(50),
	@Count VARCHAR(10) = '0',
	@Idlist VARCHAR(max) = '0',
	@SalesOrderId BIGINT
AS
	BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY

        IF @Count = '0'
            SET @Count = '20';

        SELECT DISTINCT TOP 20
            IM.ItemMasterId  AS Value,
            CONCAT(
                IM.PartNumber,
                CASE WHEN dupCounts.PartNumberCount > 1
                     THEN ' - ' + ISNULL(IM.ManufacturerName, '')
                     ELSE ''
                END
            )                AS PartNumber,
            IM.PartNumber    AS Label
        FROM dbo.ItemMaster IM WITH (NOLOCK)
        JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK)
            ON SOP.ItemMasterId = IM.ItemMasterId
        OUTER APPLY (
            SELECT COUNT(*) AS PartNumberCount
            FROM dbo.ItemMaster SD WITH (NOLOCK)
            WHERE SD.PartNumber       = IM.PartNumber
              AND SD.MasterCompanyId  = SOP.MasterCompanyId
        ) dupCounts
        WHERE IM.IsActive              = 1
          AND ISNULL(IM.IsDeleted, 0)  = 0
          AND SOP.SalesOrderId         = @SalesOrderId
          AND (
                IM.PartNumber LIKE @StartWith + '%'
             OR IM.PartNumber LIKE '%' + @StartWith + '%'
          )
        ORDER BY Label;

    END TRY   
		BEGIN CATCH      
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsSalesorderItemMaster'               
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SalesOrderId, '') as varchar(100))			  
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
END