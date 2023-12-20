


CREATE FUNCTION [dbo].[GenerateNumber](@Number int,@CodeType varchar(50))
RETURNS varchar(100)
AS
BEGIN   
	Declare @NumberLength int 
	Declare @CodeSuffix varchar(50)
	Declare @CodePrefix varchar(50)
	Declare @VersionCode varchar(50)
	SELECT @CodeSuffix=IsNull(CodeSufix,''),@CodePrefix=IsNull(CodePrefix,'')
	FROM [dbo].[CodePrefixes] WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId=(		
		SELECT ct.CodeTypeId FROM  [dbo].[CodeTypes] ct INNER JOIN [dbo].[CodePrefixes] cp 
		ON cp.[CodePrefixId]=ct.[CodeTypeId] WHERE CodeType=@CodeType);

	Set @NumberLength=LEN(@Number)

	If @NumberLength=1
	Begin
		If @CodePrefix <>'' and @CodeSuffix <>''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'000' + CAST(@Number AS varchar) + '-'+ @CodeSuffix
		End
		Else If @CodePrefix ='' and @CodeSuffix <>''
		Begin
			Set @VersionCode='000' + CAST(@Number AS varchar) + '-'+ @CodeSuffix
		End
		Else If @CodePrefix<>'' and @CodeSuffix =''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'000' + CAST(@Number AS varchar)
		End
		Else
		Begin 
			Set @VersionCode='000' + CAST(@Number AS varchar)
		End
	End
	Else If @NumberLength=2
	Begin
		If @CodePrefix <>'' and @CodeSuffix <>''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'00' + CAST(@Number AS varchar) + '-'+ @CodeSuffix
		End
		Else If @CodePrefix ='' and @CodeSuffix <>''
		Begin
			Set @VersionCode='00' + CAST(@Number AS varchar) + '-'+ @CodeSuffix
		End
		Else If @CodePrefix<>'' and @CodeSuffix =''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'00' + CAST(@Number AS varchar)
		End
		Else
		Begin 
			Set @VersionCode='00' + CAST(@Number AS varchar)
		End
	End
	Else If @NumberLength=3
	Begin
		If @CodePrefix <>'' and @CodeSuffix <>''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'0' + CAST(@Number AS varchar) + '-'+ @CodeSuffix
		End
		Else If @CodePrefix ='' and @CodeSuffix <>''
		Begin
			Set @VersionCode='0' + CAST(@Number AS varchar) + '-'+ @CodeSuffix
		End
		Else If @CodePrefix<>'' and @CodeSuffix =''
		Begin
			Set @VersionCode= @CodePrefix+'-'+'0' + CAST(@Number AS varchar)
		End
		Else
		Begin 
			Set @VersionCode='0' + CAST(@Number AS varchar)
		End
	End
	Else
	Begin
		If @CodePrefix <>'' and @CodeSuffix <>''
		Begin
			Set @VersionCode=@CodePrefix+'-'+ CAST(@Number AS varchar)+ '-'+ @CodeSuffix
		End
		Else If @CodePrefix ='' and @CodeSuffix <>''
		Begin
			Set @VersionCode= CAST(@Number AS varchar) + '-'+ @CodeSuffix
		End
		Else If @CodePrefix<>'' and @CodeSuffix =''
		Begin
			Set @VersionCode= @CodePrefix+'-'+ CAST(@Number AS varchar)
		End
		Else
		Begin 
			Set @VersionCode= CAST(@Number AS varchar)
		End
	End	
	return @VersionCode
END