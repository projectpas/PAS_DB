/*******************************************************************************************
 ** File:   [USP_VendorContactDataFilter]          
 ** Author:  Ayushi Patel
 ** Description: Returns Vendor Contact Data 
 ** Purpose:         
 ** Date:   09/05/2025      
          
 ** PARAMETERS: 
    @FilterVal NVARCHAR(200),
    @VendorId BIGINT,
    @Count INT,
    @IdList NVARCHAR(MAX),
    @MasterCompanyId INT
         
 ** RETURN VALUE:          
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    12/05/2025  Ayushi Patel	    Created
     
-- EXEC [USP_VendorContactDataFilter] NULL , 132 , 20 , 0 ,1
********************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorContactDataFilter]
    @FilterVal NVARCHAR(200) = NULL,
    @VendorId BIGINT,
    @Count INT,
    @IdList NVARCHAR(MAX),
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        IF @Count = 0
            SET @Count = 20;

        IF @FilterVal IS NULL
            SET @FilterVal = '';

        IF @IdList IS NULL OR LTRIM(RTRIM(@IdList)) = ''
            SET @IdList = '0';

        SELECT TOP (@Count)
            VC.VendorContactId,
            C.ContactId,
            vendoreContactName = CONCAT(C.FirstName, ' ', C.LastName),
            C.Email,
            C.WorkPhone,
            C.WorkPhoneExtn,
            ISNULL(VC.IsDefaultContact,0)
        FROM dbo.VendorContact VC WITH (NOLOCK)
        INNER JOIN dbo.Contact C WITH (NOLOCK) ON VC.ContactId = C.ContactId
        WHERE ISNULL(VC.IsActive,0) = 1
            AND ISNULL(VC.IsDeleted,0) = 0
            AND VC.VendorId = @VendorId
            AND VC.MasterCompanyId = @MasterCompanyId
            AND LTRIM(RTRIM(CONCAT(C.FirstName, ' ', C.LastName))) LIKE '%' + @FilterVal + '%'
        ORDER BY vendoreContactName;

        IF @IdList <> '0'
        BEGIN
            ;WITH Ids AS
            (
                SELECT value AS VendorContactId
                FROM STRING_SPLIT(@IdList, ',')
            )
            SELECT TOP (@Count)
                VC.VendorContactId,
                C.ContactId,
                vendoreContactName = CONCAT(C.FirstName, ' ', C.LastName),
                C.Email,
                C.WorkPhone,
                C.WorkPhoneExtn,
                ISNULL(VC.IsDefaultContact,0)
            FROM dbo.VendorContact VC WITH (NOLOCK)
            INNER JOIN dbo.Contact C WITH (NOLOCK) ON VC.ContactId = C.ContactId
            INNER JOIN Ids ON VC.VendorContactId = TRY_CAST(Ids.VendorContactId AS BIGINT)
            WHERE VC.VendorId = @VendorId AND ISNULL(VC.IsActive,0) = 1
            AND ISNULL(VC.IsDeleted,0) = 0
            ORDER BY vendoreContactName;
        END
    END TRY
    BEGIN CATCH
   DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_VendorContactDataFilter'
            , @ProcedureParameters VARCHAR(3000)  = ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName   = @DatabaseName  
                    , @AdhocComments   = @AdhocComments  
                    , @ProcedureParameters  = @ProcedureParameters  
                    , @ApplicationName   =  @ApplicationName  
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
    END CATCH
END